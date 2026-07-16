# Vulnerable IaC Lab

Arquivos Terraform intencionalmente vulneraveis para testes de scan IaC com Veracode.

Nao execute `terraform apply` nesta pasta. Os recursos incluem configuracoes inseguras de proposito:

- portas administrativas abertas para a internet;
- storage publico;
- secrets hardcoded;
- IMDSv1 habilitado;
- discos sem criptografia;
- Kubernetes com `privileged`, `hostPath`, `hostNetwork`, `cluster-admin` e service account token montado automaticamente.

O script `scripts/veracode-cli-scans.sh` usa `IAC_DIR=.` nas pipelines, entao esses arquivos sao incluidos no scan.
