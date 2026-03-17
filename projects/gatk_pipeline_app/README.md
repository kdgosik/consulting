# GATK Pipeline Builder (Flutter + GetX)

An interactive desktop/mobile app for building, configuring, and running GATK pipelines — built with Flutter and GetX.

---

## Features

| Feature | Details |
|---|---|
| **JAR Discovery** | Loads any GATK 4.x jar and runs `--list` to find all tools |
| **Tool Panel** | Filterable, categorized tool list with drag-and-drop support |
| **Pipeline Canvas** | Reorderable steps with per-step enable/disable toggles |
| **Argument Config** | Bottom sheet with typed fields: file pickers, dropdowns, booleans, numbers |
| **JAR Introspection** | Runs `<tool> --help` to parse real argument definitions |
| **Command Preview** | Live preview of the exact `java -jar` command per step |
| **Pipeline Runner** | Executes steps sequentially, streams stdout/stderr to the log panel |
| **Save/Load** | Persists pipelines as JSON via `shared_preferences` |
| **Log Panel** | Color-coded output with timestamps, copy-to-clipboard |

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme.dart                   # Dark theme, colors, typography
├── bindings/
│   └── app_binding.dart         # GetX dependency injection
├── controllers/
│   └── app_controller.dart      # All app state + business logic
├── models/
│   ├── gatk_tool.dart           # GatkTool, GatkArgument
│   └── pipeline.dart            # Pipeline, PipelineStep
├── services/
│   └── gatk_service.dart        # JAR introspection + process runner
├── views/
│   └── home_view.dart           # Main layout + top bar
└── widgets/
    ├── tool_panel.dart          # Left panel: tool browser
    ├── pipeline_canvas.dart     # Center: drag-drop pipeline builder
    ├── step_config_sheet.dart   # Bottom sheet: argument editor
    └── log_panel.dart           # Bottom: log output
```

---

## Setup

### Prerequisites
- Flutter 3.10+ with Dart 3.0+
- Java on your PATH (to run GATK)
- A GATK 4.x jar (e.g. `gatk-4.5.0.0.jar`)

### Install & Run

```bash
cd gatk_pipeline_app
flutter pub get
flutter run -d macos    # or windows / linux
```

### Build Release

```bash
flutter build macos     # macOS app
flutter build windows   # Windows app
flutter build linux     # Linux AppImage
```

---

## Architecture (GetX Pattern)

### State Flow
```
UI Events → AppController (reactive .obs) → UI rebuilds via Obx()
```

### Key Controller Methods

```dart
controller.pickJarFile()           // Opens file picker → loads jar
controller.addToolToPipeline(tool) // Appends step to pipeline
controller.removeStep(stepId)      // Removes a step
controller.reorderSteps(old, new)  // Drag-drop reorder
controller.toggleStepEnabled(id)   // Enable/disable step
controller.updateStepArgument(stepId, argName, value) // Update arg
controller.introspectToolArgs(stepId) // Runs <tool> --help
controller.runPipeline()           // Executes all enabled steps
controller.savePipeline()          // Saves to local storage
```

### Adding New Tools

The `GatkService._wellKnownTools()` method contains a fallback list of common GATK4 tools with their arguments. Extend this to add more tools or override default arguments.

### Extending Argument Types

In `step_config_sheet.dart`, the `_ArgField._buildInput()` switch handles:
- `file` → path text field with folder picker
- `boolean` → switch toggle
- `enum` → dropdown with known values  
- `int`, `float` → numeric keyboard
- `string` → text field (default)

Add new types here to customize rendering.

---

## Pipeline JSON Format

Pipelines are saved as JSON and can be exported/imported:

```json
{
  "id": "uuid",
  "name": "My Variant Calling Pipeline",
  "steps": [
    {
      "id": "step-uuid",
      "enabled": true,
      "tool": {
        "name": "HaplotypeCaller",
        "category": "Variant Calling",
        "arguments": [
          { "name": "input", "type": "file", "value": "/data/sample.bam", "required": true },
          { "name": "output", "type": "file", "value": "/data/output.vcf", "required": true },
          { "name": "reference", "type": "file", "value": "/ref/hg38.fa", "required": true }
        ]
      }
    }
  ]
}
```

---

## Common GATK Workflows

### Germline Variant Calling
1. `MarkDuplicates` — remove PCR duplicates
2. `BaseRecalibrator` — compute BQSR table
3. `ApplyBQSR` — apply recalibration
4. `HaplotypeCaller` — call variants (GVCF mode)
5. `GenotypeGVCFs` — joint genotyping
6. `SelectVariants` — separate SNPs and INDELs
7. `VariantFiltration` — apply hard filters

### Somatic Variant Calling (Mutect2)
1. `MarkDuplicates` — tumor + normal
2. `BaseRecalibrator` + `ApplyBQSR` — recalibrate
3. `Mutect2` — somatic calling
4. `FilterMutectCalls` — apply somatic filters

---

## Dependencies

| Package | Purpose |
|---|---|
| `get` | State management, routing, DI |
| `file_picker` | JAR and file selection dialogs |
| `path_provider` | Find app documents directory |
| `shared_preferences` | Pipeline persistence |
| `process_run` | Spawn java subprocess |
| `google_fonts` | JetBrains Mono + Space Grotesk |
| `reorderables` | Drag-to-reorder list |
| `uuid` | Generate pipeline/step IDs |




Let me rebuild this as a **web app** — which changes the architecture significantly (no Flutter, no Java process spawning directly). Instead I'll build a polished React single-page app that:

- Lets you configure and visually build GATK pipelines in the browser
- Generates the exact shell commands/scripts to run
- Simulates execution with log output (since browsers can't spawn processes directly)
- Saves/loads pipelines via localStorage… wait, that's blocked. I'll use in-memory + JSON export/import.Here's your full browser-based GATK Pipeline Builder. Here's what's packed in:

**Left panel — tool browser**
13 pre-loaded GATK4 tools across 7 categories (Variant Calling, Base Quality, Somatic, Read Manipulation, Variant Filtering, QC & Metrics, Copy Number). Filter by category or search by name/description.

**Pipeline canvas — building**
Click any tool or drag it into the canvas to add a step. Each step card shows:
- Color-coded by category
- All tool-specific arguments with typed inputs (file paths, enums/dropdowns, booleans, text)
- Required args marked in orange
- A live command preview that updates as you fill in values
- Move up/down, enable/disable toggle, and remove

**Top bar actions**
- **JAR button** — set your GATK jar path (used in all command previews and the run simulation)
- **Save / Load** — keeps pipelines in session memory with step/arg state
- **Export script** — generates a `#!/bin/bash` script with all `java -jar` commands ready to copy to your server
- **Run pipeline** — simulates execution with step-by-step log output and a progress bar

**Log panel** — timestamped output with INFO/OK/ERR/STEP tags, copyable to clipboard.

Since this runs in the browser it can't directly call Java, but the **Export script** gives you a production-ready shell script to run on any machine with GATK and Java on PATH.