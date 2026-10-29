# Inhibition Explanation (03_notifications_routing)

`alertmanager_inhibit.yml` is a second version of this folder's routing config with one
additional `inhibit_rules` section (validated with `amtool check-config`):

```yaml
inhibit_rules:
  - source_match:
      alertname: 'InstanceDown'
      severity: 'critical'
    target_match:
      alertname: 'HighCPUUsage'
      severity: 'warning'
    equal: ['instance']
```

## 1. What exactly does this rule do?

While an alert matching the source conditions is firing
(`alertname=InstanceDown`, `severity=critical`), any alert matching the target
conditions (`alertname=HighCPUUsage`, `severity=warning`) is suppressed - for the
same value of the `instance` label (`equal: ['instance']`).

Suppression means: the target alert still exists and is visible in the Alertmanager UI
and `/api/v2/alerts` (state `suppressed`), but it produces no notification to any
receiver.

Intent: when a machine is completely unreachable, *every* metric-based alert from that
machine will eventually fire (CPU, memory, disk...). Only the root cause
("the instance is down") deserves a page; the dependent symptoms are noise. The rule
hides the symptoms while the cause is active, and they automatically reappear if the
cause resolves while they still fire.

## 2. Practical example: instance is down AND had HighCPU before

Scenario: `node-7:9100` was running at 85 % CPU (so `HighCPUUsage` is already firing,
warning → logfile-receiver) and then the node crashes (`InstanceDown` fires, critical →
stdout-receiver).

With `alertmanager.yml` (no inhibition) the on-call receives:

- a critical notification: InstanceDown on node-7 → stdout-receiver
- the warning HighCPUUsage notifications for node-7 keep re-sending per
  `repeat_interval` → logfile-receiver - misleading, because nothing can measure or fix
  CPU on a dead node.

With `alertmanager_inhibit.yml` loaded instead:

- the critical InstanceDown notification is delivered as before;
- HighCPUUsage for `instance=node-7:9100` goes to state `suppressed` and
  no notification is sent for it (past notifications stop repeating too);
- HighCPUUsage on any *other* instance (different `instance` label) is unaffected -
  `equal: ['instance']` scopes suppression to the same machine only;
- if the node comes back while still overloaded, InstanceDown resolves and
  HighCPUUsage (still firing) is un-suppressed and notifies normally.

Demonstration: `inhibition_demo_output.txt` in this folder - synthetic
`InstanceDown{instance="node_exporter:9100"}` active, and two synthetic
`HighCPUUsage` alerts; the one with the same instance shows
`state: suppressed, inhibitedBy: [...]`, the one with a different instance stays
`active`, and the logfile receiver receives only the non-inhibited one.

## 3. Two more useful inhibition patterns

### 3.1 DatabaseDown suppresses ApplicationErrors (dependency cascade)
```yaml
inhibit_rules:
  - source_match:
      alertname: 'DatabaseDown'
      severity: 'critical'
    target_match:
      alertname: 'ApplicationErrors'
      severity: 'critical'
    equal: ['environment']
```
When the primary database is down, dozens of application pods start throwing 5xx at
once ("ApplicationErrors"). The DB alert is the root cause; the application alerts are
consequences. Inhibiting them per `environment` collapses a storm of pages into one
actionable "fix the database" message.

### 3.2 Datacenter/network outage suppresses per-host alerts
```yaml
inhibit_rules:
  - source_match:
      alertname: 'DatacenterUnreachable'
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['datacenter']
```
If the whole datacenter link is down (blackbox probe from outside fails), every host in
that `datacenter` will fire `InstanceDown`-class warnings. One "datacenter
unreachable" critical suppresses the flood, and the routing sub-routes can also send
datacenter-level alerts to a different (management/out-of-band) channel.

(General rule of thumb: `source` = root cause / higher aggregation level, `target` =
symptom / lower level, `equal` = the labels that tie them to the same object.)
