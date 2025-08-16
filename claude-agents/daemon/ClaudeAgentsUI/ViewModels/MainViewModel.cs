using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Reactive.Linq;
using System.Text.Json;
using Microsoft.Maui.Graphics;

namespace ClaudeAgentsUI.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly IDispatcher _dispatcher;
    private Process? _daemonProcess;
    private FileSystemWatcher? _statusWatcher;
    private FileSystemWatcher? _eventsWatcher;
    private readonly string _projectPath;
    private readonly string _daemonScript;

    [ObservableProperty]
    private string statusMessage = "Daemon Stopped";

    [ObservableProperty]
    private Color statusColor = Colors.Gray;

    [ObservableProperty]
    private bool isRunning;

    [ObservableProperty]
    private bool canStart = true;

    [ObservableProperty]
    private bool canStop = false;

    [ObservableProperty]
    private AgentStatus documentationAgent = new() { Name = "Documentation" };

    [ObservableProperty]
    private AgentStatus architectureAgent = new() { Name = "Architecture" };

    [ObservableProperty]
    private AgentStatus azureAgent = new() { Name = "Azure" };

    [ObservableProperty]
    private AgentStatus auditAgent = new() { Name = "Audit" };

    public ObservableCollection<EventItem> Events { get; } = new();

    public MainViewModel(IDispatcher dispatcher)
    {
        _dispatcher = dispatcher;
        
        // Get project path from environment or config
        _projectPath = Environment.GetEnvironmentVariable("CLAUDE_PROJECT_PATH") 
            ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), 
                           "Source", "YourProject");
        
        _daemonScript = Path.Combine(_projectPath, ".claude", "agents", "daemon", "claude-daemon.sh");
        
        InitializeWatchers();
    }

    private void InitializeWatchers()
    {
        var claudePath = Path.Combine(_projectPath, ".claude");
        if (!Directory.Exists(claudePath))
        {
            Directory.CreateDirectory(claudePath);
        }

        // Watch status file
        _statusWatcher = new FileSystemWatcher(claudePath, "daemon.status")
        {
            NotifyFilter = NotifyFilters.LastWrite,
            EnableRaisingEvents = true
        };
        _statusWatcher.Changed += OnStatusChanged;

        // Watch events file
        _eventsWatcher = new FileSystemWatcher(claudePath, "daemon.events")
        {
            NotifyFilter = NotifyFilters.LastWrite,
            EnableRaisingEvents = true
        };
        _eventsWatcher.Changed += OnEventsChanged;
    }

    private void OnStatusChanged(object sender, FileSystemEventArgs e)
    {
        try
        {
            var json = File.ReadAllText(e.FullPath);
            var status = JsonSerializer.Deserialize<DaemonStatus>(json);
            
            _dispatcher.Dispatch(() =>
            {
                UpdateAgentStatuses(status);
                StatusMessage = status?.Message ?? "Unknown";
                StatusColor = status?.Status switch
                {
                    "running" => Colors.Green,
                    "starting" => Colors.Yellow,
                    "stopping" => Colors.Orange,
                    "stopped" => Colors.Gray,
                    _ => Colors.Red
                };
                
                IsRunning = status?.Status == "running";
                CanStart = !IsRunning;
                CanStop = IsRunning;
            });
        }
        catch { }
    }

    private void OnEventsChanged(object sender, FileSystemEventArgs e)
    {
        try
        {
            var lines = File.ReadAllLines(e.FullPath);
            var lastLine = lines.LastOrDefault();
            if (!string.IsNullOrEmpty(lastLine))
            {
                var evt = JsonSerializer.Deserialize<DaemonEvent>(lastLine);
                if (evt != null)
                {
                    _dispatcher.Dispatch(() =>
                    {
                        AddEvent(evt);
                    });
                }
            }
        }
        catch { }
    }

    private void UpdateAgentStatuses(DaemonStatus? status)
    {
        if (status?.Agents == null) return;

        DocumentationAgent.Status = status.Agents.GetValueOrDefault("documentation", "idle");
        DocumentationAgent.UpdateColors();

        ArchitectureAgent.Status = status.Agents.GetValueOrDefault("architecture", "idle");
        ArchitectureAgent.UpdateColors();

        AzureAgent.Status = status.Agents.GetValueOrDefault("azure", "idle");
        AzureAgent.UpdateColors();

        AuditAgent.Status = status.Agents.GetValueOrDefault("audit", "idle");
        AuditAgent.UpdateColors();
    }

    private void AddEvent(DaemonEvent evt)
    {
        var eventItem = new EventItem
        {
            Timestamp = DateTime.Parse(evt.Timestamp),
            Agent = evt.Agent,
            Message = $"{evt.Action}: {evt.Details}",
            Level = evt.Level
        };

        eventItem.UpdateColors();

        Events.Insert(0, eventItem);

        // Keep only last 100 events
        while (Events.Count > 100)
        {
            Events.RemoveAt(Events.Count - 1);
        }
    }

    [RelayCommand]
    private async Task StartDaemon()
    {
        try
        {
            StatusMessage = "Starting daemon...";
            StatusColor = Colors.Yellow;

            var startInfo = new ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = $"{_daemonScript} start",
                WorkingDirectory = _projectPath,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            _daemonProcess = Process.Start(startInfo);
            
            if (_daemonProcess != null)
            {
                // Read output in background
                _ = Task.Run(async () =>
                {
                    while (!_daemonProcess.StandardOutput.EndOfStream)
                    {
                        var line = await _daemonProcess.StandardOutput.ReadLineAsync();
                        if (!string.IsNullOrEmpty(line))
                        {
                            _dispatcher.Dispatch(() =>
                            {
                                AddEvent(new DaemonEvent
                                {
                                    Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                                    Agent = "daemon",
                                    Action = "Output",
                                    Details = line,
                                    Level = "info"
                                });
                            });
                        }
                    }
                });

                await Task.Delay(2000); // Give daemon time to start
                StatusMessage = "Daemon running";
                StatusColor = Colors.Green;
                IsRunning = true;
                CanStart = false;
                CanStop = true;
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
            StatusColor = Colors.Red;
        }
    }

    [RelayCommand]
    private async Task StopDaemon()
    {
        try
        {
            StatusMessage = "Stopping daemon...";
            StatusColor = Colors.Orange;

            var stopInfo = new ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = $"{_daemonScript} stop",
                WorkingDirectory = _projectPath,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            var stopProcess = Process.Start(stopInfo);
            await stopProcess!.WaitForExitAsync();

            _daemonProcess?.Kill();
            _daemonProcess?.Dispose();
            _daemonProcess = null;

            StatusMessage = "Daemon stopped";
            StatusColor = Colors.Gray;
            IsRunning = false;
            CanStart = true;
            CanStop = false;
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
            StatusColor = Colors.Red;
        }
    }

    [RelayCommand]
    private void ClearLog()
    {
        Events.Clear();
    }

    [RelayCommand]
    private async Task RunAudit()
    {
        if (!IsRunning) return;

        try
        {
            var auditInfo = new ProcessStartInfo
            {
                FileName = "claude",
                Arguments = "\"As the Audit Orchestration Agent, perform a quick audit check\"",
                WorkingDirectory = _projectPath,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true
            };

            var auditProcess = Process.Start(auditInfo);
            var output = await auditProcess!.StandardOutput.ReadToEndAsync();
            
            AddEvent(new DaemonEvent
            {
                Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                Agent = "audit",
                Action = "Manual Check",
                Details = output.Substring(0, Math.Min(output.Length, 100)),
                Level = "info"
            });
        }
        catch (Exception ex)
        {
            AddEvent(new DaemonEvent
            {
                Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                Agent = "audit",
                Action = "Error",
                Details = ex.Message,
                Level = "error"
            });
        }
    }
}

public partial class AgentStatus : ObservableObject
{
    [ObservableProperty]
    private string name = "";

    [ObservableProperty]
    private string status = "idle";

    [ObservableProperty]
    private Color backgroundColor = Colors.LightGray;

    [ObservableProperty]
    private Color borderColor = Colors.Gray;

    [ObservableProperty]
    private Color statusColor = Colors.Black;

    public void UpdateColors()
    {
        switch (Status.ToLower())
        {
            case "running":
                BackgroundColor = Colors.LightGreen;
                BorderColor = Colors.Green;
                StatusColor = Colors.DarkGreen;
                break;
            case "idle":
                BackgroundColor = Colors.LightGray;
                BorderColor = Colors.Gray;
                StatusColor = Colors.Black;
                break;
            case "error":
                BackgroundColor = Colors.LightCoral;
                BorderColor = Colors.Red;
                StatusColor = Colors.DarkRed;
                break;
            default:
                BackgroundColor = Colors.LightYellow;
                BorderColor = Colors.Orange;
                StatusColor = Colors.DarkOrange;
                break;
        }
    }
}

public partial class EventItem : ObservableObject
{
    [ObservableProperty]
    private DateTime timestamp;

    [ObservableProperty]
    private string agent = "";

    [ObservableProperty]
    private string message = "";

    [ObservableProperty]
    private string level = "info";

    [ObservableProperty]
    private Color backgroundColor = Colors.White;

    [ObservableProperty]
    private Color textColor = Colors.Black;

    [ObservableProperty]
    private Color agentColor = Colors.Blue;

    public void UpdateColors()
    {
        switch (Level.ToLower())
        {
            case "error":
                BackgroundColor = Color.FromRgba("#FFE5E5");
                TextColor = Colors.DarkRed;
                break;
            case "warning":
                BackgroundColor = Color.FromRgba("#FFF5E5");
                TextColor = Colors.DarkOrange;
                break;
            case "success":
                BackgroundColor = Color.FromRgba("#E5FFE5");
                TextColor = Colors.DarkGreen;
                break;
            default:
                BackgroundColor = Colors.White;
                TextColor = Colors.Black;
                break;
        }

        AgentColor = Agent.ToLower() switch
        {
            "documentation" => Colors.Purple,
            "architecture" => Colors.Blue,
            "azure" => Colors.Teal,
            "audit" => Colors.Green,
            _ => Colors.Gray
        };
    }
}

public class DaemonStatus
{
    public string Status { get; set; } = "";
    public string Message { get; set; } = "";
    public string Timestamp { get; set; } = "";
    public int Pid { get; set; }
    public Dictionary<string, string> Agents { get; set; } = new();
}

public class DaemonEvent
{
    public string Timestamp { get; set; } = "";
    public string Agent { get; set; } = "";
    public string Action { get; set; } = "";
    public string Details { get; set; } = "";
    public string Level { get; set; } = "";
}