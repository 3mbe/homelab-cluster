# `deploy.sh`

A simple, daily-driver script for managing a local **ephemeral Talos K8s cluster** using Docker.

Designed for fast, throwaway environments; perfect for testing, tinkering, or starting fresh each day without carrying over old state.

The script provides three commands:

- **`up`** – Create a Talos cluster  
- **`destroy`** – Remove a cluster by name  
- **`status`** – Show the current Kubernetes context and node status  

---

## Requirements

- Docker  
- Talos CLI (`talosctl`)  
- `kubectl`  
- `k9s` (optional; detected automatically)

---

## Usage

```bash
./deploy.sh up [cluster-name]
./deploy.sh destroy <cluster-name>
./deploy.sh status
```

---
## Notes
- If no cluster name is provided, Talos uses its default naming.