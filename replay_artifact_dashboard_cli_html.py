import json
import argparse
import csv
import time
from datetime import datetime
from collections import Counter
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress

console = Console()

def load_artifacts(filename="artifact_log.json"):
    """Load artifacts from JSON log file."""
    try:
        with open(filename, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        console.print(f"[red]No artifact log found at {filename}[/red]")
        return []

def filter_artifacts(artifacts, types=None, sources=None, start_time=None, end_time=None):
    """Filter artifacts by type, source, and time range."""
    filtered = []
    for art in artifacts:
        if types and art.get("type") not in types:
            continue
        if sources and art.get("source") not in sources:
            continue
        if start_time or end_time:
            try:
                ts = datetime.strptime(art.get("timestamp"), "%Y-%m-%d %H:%M:%S")
                if start_time and ts < start_time:
                    continue
                if end_time and ts > end_time:
                    continue
            except Exception:
                pass
        filtered.append(art)
    return filtered

def show_artifact_dashboard(artifacts, title="Artifact Injection Log"):
    console.print("="*60, style="bold blue")
    console.print(f"SOC SIMULATION ARTIFACT REVIEW – {title}", style="bold cyan")
    console.print("="*60, style="bold blue")

    artifact_table = Table(title="[cyan]Filtered Artifact Log[/cyan]")
    artifact_table.add_column("ID", style="magenta")
    artifact_table.add_column("Type", style="yellow")
    artifact_table.add_column("Timestamp", style="cyan")
    artifact_table.add_column("Source", style="green")
    artifact_table.add_column("Description", style="white")

    for art in artifacts:
        artifact_table.add_row(
            art.get("artifact_id", ""),
            art.get("type", ""),
            art.get("timestamp", ""),
            art.get("source", ""),
            art.get("description", "")
        )

    console.print(artifact_table)
    console.print(Panel.fit(
        f"Total artifacts displayed: {len(artifacts)}",
        title="[green]Summary[/green]"
    ))
    console.print("="*60, style="bold blue")

def export_to_csv(artifacts, filename="filtered_artifacts.csv"):
    """Export filtered artifacts to CSV."""
    if not artifacts:
        console.print("[yellow]No artifacts to export.[/yellow]")
        return
    with open(filename, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["artifact_id", "type", "timestamp", "source", "description"])
        writer.writeheader()
        writer.writerows(artifacts)
    console.print(f"[green]Filtered artifacts exported to {filename}[/green]")

def export_to_html(artifacts, filename="report.html"):
    type_counts = Counter([art["type"] for art in artifacts])
    source_counts = Counter([art["source"] for art in artifacts])
    """Export artifacts and summary charts to HTML report."""

    # Assign colors per artifact type
    type_colors = {
        "pcap": "#e74c3c",      # red
        "logfile": "#3498db",   # blue
        "alert": "#2ecc71",     # green
        "email": "#9b59b6",     # purple
        "default": "#f39c12"    # orange fallback
    }

    css = """
    <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1, h2, h3 { color: #2c3e50; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    .bar-container { background: #f0f0f0; width: 300px; display: inline-block; margin-left: 10px; }
    .bar { height: 20px; text-align: right; padding-right: 5px; color: white; font-size: 12px; }
    </style>
    """

    html = ["<html><head><title>Artifact Replay Report</title>", css, "</head><body>"]
    html.append("<h1>Artifact Replay Report</h1>")
    html.append("<h2>Filtered Artifacts</h2>")
    html.append("<table><tr><th>ID</th><th>Type</th><th>Timestamp</th><th>Source</th><th>Description</th></tr>")
    for art in artifacts:
        html.append(f"<tr><td>{art['artifact_id']}</td><td>{art['type']}</td>"
                    f"<td>{art['timestamp']}</td><td>{art['source']}</td><td>{art['description']}</td></tr>")
    html.append("</table>")

    # Summary charts with color-coded bars
    html.append("<h2>Summary Charts</h2>")
    html.append("<h3>By Type</h3>")
    for t, c in type_counts.items():
        width = c * 30
        color = type_colors.get(t, type_colors["default"])
        html.append(f"<div>{t}: <div class='bar-container'><div class='bar' style='width:{width}px; background:{color}'>{c}</div></div></div>")

    html.append("<h3>By Source</h3>")
    for s, c in source_counts.items():
        width = c * 30
        # Sources can all use default color for now
        html.append(f"<div>{s}: <div class='bar-container'><div class='bar' style='width:{width}px; background:#34495e'>{c}</div></div></div>")

    html.append("</body></html>")

    with open(filename, "w") as f:
        f.write("\n".join(html))
    console.print(f"[green]HTML report with color-coded charts saved to {filename}[/green]")

    html.append("</body></html>")

    with open(filename, "w") as f:
        f.write("\n".join(html))
    console.print(f"[green]HTML report with color-coded charts saved to {filename}[/green]")

def replay_artifacts(artifacts, delay=2, loop=False, chartlog=None, htmlreport=None):
    """Replay artifacts one by one with delays, with progress bar and summary charts."""
    console.print("[cyan]Replaying artifact feed...[/cyan]")
    try:
        while True:
            with Progress() as progress:
                task = progress.add_task("[green]Replaying...", total=len(artifacts))
                for art in artifacts:
                    console.print(f"[magenta]{art['artifact_id']}[/magenta] | "
                                  f"[yellow]{art['type']}[/yellow] | "
                                  f"[cyan]{art['timestamp']}[/cyan] | "
                                  f"[green]{art['source']}[/green] | "
                                  f"{art['description']}")
                    time.sleep(delay)
                    progress.update(task, advance=1)

            # Summary stats after each replay cycle
            type_counts = Counter([art["type"] for art in artifacts])
            source_counts = Counter([art["source"] for art in artifacts])

            console.print("\n[bold green]Artifact Counts by Type[/bold green]")
            for t, c in type_counts.items():
                console.print(f"{t:15} | {'█' * c} ({c})")

            console.print("\n[bold cyan]Artifact Counts by Source[/bold cyan]")
            for s, c in source_counts.items():
                console.print(f"{s:15} | {'█' * c} ({c})")

            # Save charts to file if requested
            if chartlog:
                with open(chartlog, "w") as f:
                    f.write("Artifact Counts by Type\n")
                    for t, c in type_counts.items():
                        f.write(f"{t:15} | {'█' * c} ({c})\n")
                    f.write("\nArtifact Counts by Source\n")
                    for s, c in source_counts.items():
                        f.write(f"{s:15} | {'█' * c} ({c})\n")
                console.print(f"[green]Summary charts saved to {chartlog}[/green]")

            if htmlreport:
                export_to_html(artifacts, filename=htmlreport)

            if not loop:
                break
    except KeyboardInterrupt:
        console.print("[red]Replay stopped by user.[/red]")

def get_delay_from_speed(speed):
    """Map speed presets to delay seconds."""
    if speed == "fast":
        return 1
    elif speed == "slow":
        return 5
    else:  # normal
        return 2

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Replay SOC artifact dashboard with filters, export, progress bar, charts, and HTML report")
    parser.add_argument("--type", nargs="*", help="Filter by artifact type(s), e.g. --type pcap logfile")
    parser.add_argument("--source", nargs="*", help="Filter by artifact source(s), e.g. --source 'Web Server' Endpoint")
    parser.add_argument("--file", default="artifact_log.json", help="Artifact log file (default: artifact_log.json)")
    parser.add_argument("--from", dest="from_time", help="Start time (YYYY-MM-DD HH:MM:SS)")
    parser.add_argument("--to", dest="to_time", help="End time (YYYY-MM-DD HH:MM:SS)")
    parser.add_argument("--export", help="Export filtered results to CSV file, e.g. --export results.csv")
    parser.add_argument("--replay", action="store_true", help="Replay artifacts one by one with delays")
    parser.add_argument("--delay", type=int, help="Custom delay in seconds between replayed artifacts")
    parser.add_argument("--speed", choices=["fast", "normal", "slow"], help="Replay speed preset")
    parser.add_argument("--loop", action="store_true", help="Continuously loop replay until stopped")
    parser.add_argument("--chartlog", help="Save summary charts to text file, e.g. --chartlog charts.txt")
    parser.add_argument("--htmlreport", help="Save full report to HTML file, e.g. --htmlreport report.html")
    args = parser.parse_args()

    start_time = datetime.strptime(args.from_time, "%Y-%m-%d %H:%M:%S") if args.from_time else None
    end_time = datetime.strptime(args.to_time, "%Y-%m-%d %H:%M:%S") if args.to_time else None

    artifacts = load_artifacts(args.file)
    if artifacts:
        filtered = filter_artifacts(
            artifacts,
            types=args.type,
            sources=args.source,
            start_time=start_time,
            end_time=end_time
        )

        title = (
            f"Filtered by type={args.type} source={args.source} "
            f"time={args.from_time}→{args.to_time}"
            if (args.type or args.source or args.from_time or args.to_time)
            else "All Artifacts"
        )
        show_artifact_dashboard(filtered, title=title)

        if args.export:
            export_to_csv(filtered, filename=args.export)

        if args.replay:
            # Determine delay
            if args.delay:
                delay = args.delay
            elif args.speed:
                delay = get_delay_from_speed(args.speed)
            else:
                delay = 2  # default normal
            replay_artifacts(
                filtered,
                delay=delay,
                loop=args.loop,
                chartlog=args.chartlog,
                htmlreport=args.htmlreport
            )

        # If user only wants HTML report without replay
        if args.htmlreport and not args.replay:
            export_to_html(filtered, filename=args.htmlreport)
