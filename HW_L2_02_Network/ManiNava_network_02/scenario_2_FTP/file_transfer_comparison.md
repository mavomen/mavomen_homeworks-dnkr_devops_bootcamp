# FTP vs SFTP vs SCP

## 1. Main differences

| | FTP | SFTP | SCP |
|---|---|---|---|
| Full name | File Transfer Protocol | SSH File Transfer Protocol | Secure Copy Protocol |
| Port | 21 (+ random data ports) | 22 | 22 |
| Encryption | none (plain text, even passwords) | yes (over SSH) | yes (over SSH) |
| Underlying protocol | its own (TCP) | SSH | SSH / rcp-style |
| Features | rich: dirs, resume, modes | richest: listing, resume, perms, rename | just copy files |
| Connection model | control + separate data channel | single connection | single connection |

The big one: FTP predates encryption - everything including the password
travels in clear text. SFTP and SCP tunnel through SSH so the whole session
is encrypted.

## 2. Pros and cons

**FTP**
- + simple, supported everywhere, fast on huge transfers (no encrypt overhead)
- + fine inside trusted isolated networks
- - no encryption at all (credentials + data sniffable)
- - annoying firewall/NAT behavior because of the separate data channel
- - basically dead on the public internet

**SFTP**
- + encrypted (auth + data)
- + full file operations: ls, rm, mkdir, chmod, resume interrupted transfers
- + only port 22 needed -> firewall friendly
- + key-based auth like normal SSH
- - slower than plain FTP (encryption overhead)
- - needs an SSH server on the target

**SCP**
- + encrypted, very simple syntax, great for quick scripted copies
- + faster than SFTP for bulk copy of many small files (older versions)
- - can only copy files, no listing/editing/rename/resume
- - being phased out in OpenSSH (legacy protocol quirks), SFTP is the successor

## 3. Which one for which scenario

- **Internal legacy device that only speaks FTP** (old router/printer backup):
  FTP - but only inside an isolated VLAN, never over the internet.
- **Automated nightly sync / managed file transfer between servers**:
  SFTP - encrypted, scriptable, supports chroot jail per user (OpenSSH internal-sftp).
- **One-off "copy this tarball to the server" from a shell**:
  SCP - shortest command, done.

In production today it's basically SFTP or SCP; plain FTP is considered insecure.

## 4. Example commands

```bash
# FTP (interactive client)
ftp ftp.gnu.org
# then: user anonymous anonymous / ls / get README / bye

# SFTP (interactive)
sftp ftpuser@192.168.1.10
# then: ls / get file.txt / put backup.tar.gz / bye

# SCP (one-shot copies)
scp backup.tar.gz user@192.168.1.10:/backups/
scp -P 2222 -i ~/.ssh/mykey user@server:/var/log/syslog ./syslog_copy
```
