# OpenClaw Tools v1.0.0

**8 essential tools for monitoring, securing, and optimizing your OpenClaw deployment.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/fredbeddows/openclaw-tools)

## 🚀 One-Line Install

```bash
curl -fsSL https://get.openclaw.tools | bash
```

Or manually:

```bash
wget https://github.com/fredbeddows/openclaw-tools/releases/download/v1.0.0/openclaw-tools-v1.0.0.tar.gz
tar -xzf openclaw-tools-v1.0.0.tar.gz
sudo ./install.sh
```

## 📦 What's Included

### 🔒 Security Tools
| Tool | Command | Description |
|------|---------|-------------|
| **Security Audit** | `oct-security-audit` | Full security audit with pattern detection (brute force, privilege escalation, malware) |
| **Fast Security Check** | `oct-security-fast` | Quick 30-second security health check |

### 📊 Monitoring Tools
| Tool | Command | Description |
|------|---------|-------------|
| **Daily Audit** | `oct-daily-audit` | Comprehensive daily system optimization report |
| **System Monitor** | `oct-monitor` | Real-time unified system monitoring |
| **Cost Tracker** | `oct-cost-track` | Accurate API cost tracking by model/provider |

### 📈 Tracking Tools
| Tool | Command | Description |
|------|---------|-------------|
| **Token Tracker** | `oct-token-track` | Daily token usage with model breakdown |
| **Token Summary** | `oct-token-summary` | Aggregate token reports across date ranges |
| **Health Check** | `oct-health-check` | Complete system health diagnostic |

## 🎯 Quick Start

```bash
# Run a quick security check
oct-security-fast

# Generate daily optimization report
oct-daily-audit

# Check today's token usage
oct-token-track

# Full system health check
oct-health-check
```

## 🔧 Requirements

- Linux/macOS/WSL
- Bash 4.0+
- `curl`, `jq`
- OpenClaw CLI (for some features)

## 📋 Tool Details

### Security Audit (`oct-security-audit`)

Detects security patterns, not just individual events:
- SSH brute force attempts (5+ failures from same IP)
- Privilege escalation patterns
- Malware indicators (suspicious cron, hidden processes)
- Failed sudo attempts
- Listening ports audit
- Recent package installations

### Daily Audit (`oct-daily-audit`)

Comprehensive system report:
- RAM usage analysis
- Ollama/local model status
- Cron job health
- OpenClaw session stats
- Token usage summary
- Cost estimates
- System optimization suggestions

### Token Tracker (`oct-token-track`)

Track AI usage across models:
- Input/output token breakdown
- Per-model usage statistics
- Provider-level aggregation
- Daily cost estimation
- Session count by provider

## 🔄 Automation

Add to your crontab for automated monitoring:

```bash
# Daily audit at 6 AM
0 6 * * * /usr/local/bin/oct-daily-audit

# Security check every 4 hours
0 */4 * * * /usr/local/bin/oct-security-fast

# Weekly token summary (Sundays at 10 PM)
0 22 * * 0 /usr/local/bin/oct-token-summary --week
```

## 🛠️ Configuration

Tools respect these environment variables:

```bash
# Custom install location
export OPENCLAW_TOOLS_DIR=/opt/openclaw-tools

# Custom report directory
export OPENCLAW_REPORT_DIR=/var/log/openclaw

# Timezone for reports
export TZ=America/Toronto
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## 📞 Support

- Issues: [GitHub Issues](https://github.com/fredbeddows/openclaw-tools/issues)
- Discussions: [GitHub Discussions](https://github.com/fredbeddows/openclaw-tools/discussions)

---

Built for the OpenClaw community. 🔧
