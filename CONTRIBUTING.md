# Contributing

Thank you for your interest in contributing to this project! Please follow the guidelines below.

## How to Contribute

1. **Fork** the repository.
2. **Create a branch** for your feature or fix (`git checkout -b feature/my-change`).
3. **Make your changes** and validate:
   - Run `terraform fmt -recursive` to format code.
   - Run `terraform validate` to check configuration validity.
4. **Commit** your changes with a clear, descriptive message.
5. **Open a Pull Request** against the `main` branch.

## Code Standards

- Follow the [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style).
- All variables and outputs must include a `description`.
- Include or update usage examples in the `examples/` directory where applicable.
- Update `CHANGELOG.md` with a summary of your changes.
- Keep modules focused and single-purpose.
- Use meaningful resource and variable names.

## Reporting Issues

Open a GitHub Issue with a clear description, steps to reproduce, and expected vs. actual behaviour.

## Code of Conduct

Be respectful and constructive in all interactions. We are committed to providing a welcoming and inclusive experience for everyone.
