# Hall Pass Web App - Deployment Guide

## Infrastructure Overview

| Component | Location | IP Address | Notes |
|-----------|----------|------------|-------|
| Proxmox Host | infra-node | 192.168.71.20 | Main hypervisor |
| Hall Pass Web Container | LXC 115 | Inside Proxmox | Container name: `hallpass-web` |
| Supabase | VM 111 | Inside Proxmox | Backend database |

## Hall Pass Web App

### Container Details
- **Proxmox VMID**: 115
- **Container Name**: hallpass-web
- **App Directory**: `/opt/hallpass`
- **Process Manager**: PM2
- **PM2 Process Name**: `hallpass-web`

### Connection Commands

```bash
# SSH to Proxmox host
ssh root@192.168.71.20

# Execute commands in container
pct exec 115 -- bash -c '<command>'

# Enter container shell
pct enter 115

# Check PM2 status
pct exec 115 -- pm2 list

# View app logs
pct exec 115 -- pm2 logs hallpass-web

# Restart app
pct exec 115 -- pm2 restart hallpass-web
```

### Deployment Process

Since the container doesn't have git configured, deploy by copying files:

```bash
# From local machine - copy file to Proxmox, then push to container
scp <local-file> root@192.168.71.20:/tmp/
ssh root@192.168.71.20 "pct push 115 /tmp/<file> /opt/hallpass/<path>/<file>"

# Then rebuild and restart
ssh root@192.168.71.20 "pct exec 115 -- bash -c 'cd /opt/hallpass && npm run build && pm2 restart hallpass-web'"
```

### Quick Deploy (All Steps)

```bash
# Copy updated services
scp src/services/classroom.ts root@192.168.71.20:/tmp/classroom.ts
ssh root@192.168.71.20 "pct push 115 /tmp/classroom.ts /opt/hallpass/src/services/classroom.ts"

# Rebuild and restart
ssh root@192.168.71.20 "pct exec 115 -- bash -c 'cd /opt/hallpass && npm run build && pm2 restart hallpass-web'"
```

### File Locations in Container

```
/opt/hallpass/
├── .env.local          # Environment variables
├── .next/              # Next.js build output
├── ecosystem.config.js # PM2 configuration
├── node_modules/       # Dependencies
├── package.json        # Project dependencies
├── public/             # Static assets
└── src/
    ├── app/            # Next.js pages
    ├── components/     # React components
    ├── contexts/       # React contexts
    ├── lib/            # Utilities
    ├── services/       # API services
    └── types/          # TypeScript types
```

## Domain

- **Production URL**: https://hallpassedu.com
- **Managed via**: Cloudflare (DNS + proxy)

## Supabase

- **Project URL**: https://hnegcvzcugtcvoqgmgbb.supabase.co
- **Dashboard**: https://supabase.com/dashboard/project/hnegcvzcugtcvoqgmgbb
- **Auth emails**: Configured via Resend

## Troubleshooting

### App not responding
```bash
# Check if container is running
ssh root@192.168.71.20 "pct list"

# Check PM2 process
ssh root@192.168.71.20 "pct exec 115 -- pm2 list"

# View recent logs
ssh root@192.168.71.20 "pct exec 115 -- pm2 logs hallpass-web --lines 50"

# Restart PM2 process
ssh root@192.168.71.20 "pct exec 115 -- pm2 restart hallpass-web"
```

### Build errors
```bash
# View full build output
ssh root@192.168.71.20 "pct exec 115 -- bash -c 'cd /opt/hallpass && npm run build'"

# Check TypeScript errors
ssh root@192.168.71.20 "pct exec 115 -- bash -c 'cd /opt/hallpass && npx tsc --noEmit'"
```
