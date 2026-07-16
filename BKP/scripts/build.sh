#!/usr/bin/env bash
set -euo pipefail

dotnet restore VeracodeMicroservicesLab.slnx
dotnet build VeracodeMicroservicesLab.slnx -c Release --no-restore
