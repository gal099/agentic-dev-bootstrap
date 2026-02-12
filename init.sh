#!/usr/bin/env bash
#
# Agentic Development Template Initializer
#
# Interactive setup script for configuring the template in your project
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Template directory (where this script is located)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

ask_question() {
    local question=$1
    local default=$2
    local response

    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}?${NC}) $question [$default]: " response
        response=${response:-$default}
    else
        read -p "$(echo -e ${BLUE}?${NC}) $question: " response
    fi

    echo "$response"
}

ask_yes_no() {
    local question=$1
    local default=$2
    local response

    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${BLUE}?${NC}) $question [Y/n]: " response
        response=${response:-y}
    else
        read -p "$(echo -e ${BLUE}?${NC}) $question [y/N]: " response
        response=${response:-n}
    fi

    [[ "$response" =~ ^[Yy] ]]
}

# Start
clear
print_header "🤖 Agentic Development Template Setup"

echo "This script will help you set up agentic workflows in your project."
echo ""

# Step 1: Determine target directory
print_header "📁 Project Location"

TARGET_DIR=$(ask_question "Where should we set up the template?" ".")
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

print_info "Target directory: $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    print_success "Created directory: $TARGET_DIR"
fi

cd "$TARGET_DIR"

# Step 2: Project type
print_header "🎯 Project Configuration"

echo "What type of project are you building?"
echo "  1) Web Application (frontend + backend)"
echo "  2) API Service (backend only)"
echo "  3) Script/Tool (Python/Node utility)"
echo "  4) Other/Custom"
echo ""

PROJECT_TYPE=$(ask_question "Select project type" "1")

case $PROJECT_TYPE in
    1) PROJECT_TYPE_NAME="web-app" ;;
    2) PROJECT_TYPE_NAME="api-service" ;;
    3) PROJECT_TYPE_NAME="script-tool" ;;
    *) PROJECT_TYPE_NAME="custom" ;;
esac

print_info "Project type: $PROJECT_TYPE_NAME"

PROJECT_NAME=$(ask_question "Project name" "my-agentic-project")
print_info "Project name: $PROJECT_NAME"

# Step 3: Feature selection
print_header "🔧 Feature Selection"

ENABLE_SECURITY=false
ENABLE_WORKTREES=false
ENABLE_NOTION=false

if ask_yes_no "Enable security hooks? (blocks dangerous commands, protects .env files)" "y"; then
    ENABLE_SECURITY=true
    print_success "Security hooks will be enabled"
else
    print_info "Security hooks disabled (you can enable later)"
fi

if ask_yes_no "Enable multi-agent workflows with git worktrees?" "n"; then
    ENABLE_WORKTREES=true
    print_success "Git worktrees support will be enabled"
else
    print_info "Multi-agent workflows disabled (single-agent mode)"
fi

# Step 4: Copy core files
print_header "📦 Installing Template Files"

# Create core directories
mkdir -p .claude/commands
mkdir -p adws/adw_modules
mkdir -p specs
mkdir -p agents

print_success "Created directory structure"

# Copy core .claude configuration
cp -r "$TEMPLATE_DIR/core/.claude/"* .claude/
print_success "Copied Claude Code configuration"

# Copy core ADW modules
cp -r "$TEMPLATE_DIR/core/adws/"* adws/
print_success "Copied workflow modules"

# Step 5: Apply feature configurations
if [ "$ENABLE_SECURITY" = true ]; then
    mkdir -p .claude/hooks
    mkdir -p .claude/logs
    cp "$TEMPLATE_DIR/advanced/hooks/pre_tool_use.py" .claude/hooks/
    cp "$TEMPLATE_DIR/advanced/hooks/post_tool_use.py" .claude/hooks/

    # Update settings.json with hooks
    cp "$TEMPLATE_DIR/advanced/hooks/settings.advanced.json" .claude/settings.json

    print_success "Installed security hooks"

    # Add to .gitignore
    if [ -f .gitignore ]; then
        if ! grep -q ".claude/logs/" .gitignore; then
            echo ".claude/logs/" >> .gitignore
            print_success "Added .claude/logs/ to .gitignore"
        fi
    else
        echo ".claude/logs/" > .gitignore
        print_success "Created .gitignore with .claude/logs/"
    fi
fi

# Step 6: Initialize Python environment
print_header "🐍 Python Environment Setup"

if command -v uv &> /dev/null; then
    print_success "uv is installed"

    if ask_yes_no "Initialize Python project with uv?" "y"; then
        if [ ! -f "pyproject.toml" ]; then
            uv init --python 3.12 --name "$PROJECT_NAME"
            print_success "Initialized Python project"
        else
            print_info "pyproject.toml already exists, skipping init"
        fi

        # Add required dependencies
        uv add pydantic
        print_success "Added pydantic dependency"

        # Make ADW scripts executable
        chmod +x adws/*.py 2>/dev/null || true
        print_success "Made workflow scripts executable"
    fi
else
    print_warning "uv not found. Install it from: https://docs.astral.sh/uv/"
    print_info "You'll need to manually set up Python dependencies later"
fi

# Step 7: Git setup
print_header "🌿 Git Configuration"

if [ -d .git ]; then
    print_info "Git repository already initialized"
else
    if ask_yes_no "Initialize git repository?" "y"; then
        git init
        print_success "Initialized git repository"

        # Create initial commit with template
        git add .
        git commit -m "chore: initialize project with agentic-dev-template" || print_warning "Could not create initial commit"
        print_success "Created initial commit"
    fi
fi

# Step 8: Create project README
print_header "📝 Documentation"

if [ ! -f README.md ] || ask_yes_no "README.md exists. Overwrite with template?" "n"; then
    cat > README.md <<EOF
# $PROJECT_NAME

${PROJECT_TYPE_NAME^} project with agentic development workflows.

## Quick Start

### 1. Understand the codebase
\`\`\`bash
claude -p /prime
\`\`\`

### 2. Plan a feature
\`\`\`bash
claude -p "/feature" -- "Your feature description"
\`\`\`

### 3. Implement
\`\`\`bash
claude -p /implement specs/plan-{adw_id}-{name}.md
\`\`\`

### 4. Test
\`\`\`bash
claude -p /test
\`\`\`

## Using ADW Workflows

Run the complete Plan + Build workflow:

\`\`\`bash
uv run adws/adw_plan_build.py 123
\`\`\`

## Available Commands

Run \`claude -p /tools\` to see all available slash commands.

## Project Structure

- \`.claude/commands/\` - Slash command templates
- \`adws/\` - Workflow orchestration scripts
- \`specs/\` - Implementation plans
- \`agents/\` - Workflow execution data

## Features Enabled

- ✅ Core workflows (plan, build, test)
- ✅ State management
- ✅ Git integration
EOF

    if [ "$ENABLE_SECURITY" = true ]; then
        echo "- ✅ Security hooks" >> README.md
    fi

    if [ "$ENABLE_WORKTREES" = true ]; then
        echo "- ✅ Multi-agent workflows (worktrees)" >> README.md
    fi

    cat >> README.md <<EOF

## Learn More

See the [template documentation](https://github.com/gal099/agentic-dev-template) for details.
EOF

    print_success "Created README.md"
fi

# Step 9: Final summary
print_header "✨ Setup Complete!"

echo "Your project is ready for agentic development!"
echo ""
echo "📁 Location: $TARGET_DIR"
echo "🎯 Project: $PROJECT_NAME ($PROJECT_TYPE_NAME)"
echo ""
echo "Enabled features:"
echo "  • Core workflows (plan, build, test)"
echo "  • State management & git integration"
[ "$ENABLE_SECURITY" = true ] && echo "  • Security hooks"
[ "$ENABLE_WORKTREES" = true ] && echo "  • Multi-agent workflows"
echo ""
echo "Next steps:"
echo ""
echo "  1. Review .claude/commands/ for available slash commands"
echo "  2. Run: ${GREEN}claude -p /prime${NC} to understand your codebase"
echo "  3. Start coding: ${GREEN}claude -p \"/feature\" -- \"Your idea\"${NC}"
echo ""
echo "Need help? Check README.md or visit:"
echo "  https://github.com/gal099/agentic-dev-template"
echo ""
print_success "Happy coding with AI agents! 🤖"
