# Security Policy

## Supported Versions

Only the latest version of the application is currently supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of our application seriously. If you have found a vulnerability, please report it to us immediately.

**DO NOT** create a public GitHub issue for security vulnerabilities.

### How to Report

Please email the details of the vulnerability to: **johnchangsan39@gmail.com** (Replace with actual email if known, otherwise use generic placeholder or instruct to contact main developer). 
*Since I don't have the user's email, I'll use a placeholder.*

Please include:
*   Description of the vulnerability.
*   Steps to reproduce.
*   Potential impact.

We will acknowledge your report within 48 hours and provide an estimated timeline for a fix.

## Security Measures

*   All API keys are secured using environment variables.
*   Database access is restricted via Row Level Security (RLS) policies.
*   Authentication is handled via Supabase Auth services.
