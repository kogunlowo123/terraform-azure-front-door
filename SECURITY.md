# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

- **Email:** kogunlowo@gmail.com
- **Do NOT** open a public GitHub issue for security vulnerabilities.

Please include:
- A description of the vulnerability.
- Steps to reproduce the issue.
- Any potential impact or severity assessment.

We will acknowledge receipt within 48 hours and provide a timeline for a fix.

## Security Best Practices

When using or contributing to this module, follow these guidelines:

- **No secrets in code.** Never hard-code credentials, keys, or passwords in Terraform files.
- **Use `sensitive = true`** on variables and outputs that contain secrets or personally identifiable information.
- **Enable encryption** for all data at rest and in transit where supported by the Azure resource.
- **Apply least privilege.** Grant only the minimum permissions required for service principals, managed identities, and RBAC roles.
- **Keep providers up to date.** Regularly update the AzureRM provider and Terraform core to receive security patches.
- **Use remote state with encryption.** Store Terraform state in an Azure Storage Account with encryption enabled and access controls applied.
- **Review plans before apply.** Always inspect `terraform plan` output before applying changes to production.
