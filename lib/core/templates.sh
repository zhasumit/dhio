#!/bin/bash
# Note templates system

TEMPLATES_DIR="$NOTES_DIR/.templates"

# Initialize templates directory
init_templates() {
    mkdir -p "$TEMPLATES_DIR"
    
    # Create default templates if they don't exist
    create_default_templates
}

# Create default templates
create_default_templates() {
    # Meeting Notes Template
    if [ ! -f "$TEMPLATES_DIR/meeting.md" ]; then
        cat > "$TEMPLATES_DIR/meeting.md" << 'EOF'
# Meeting: {{TITLE}}

**Date:** {{DATE}}
**Attendees:** 
- 

## Agenda
1. 
2. 
3. 

## Discussion
- 

## Action Items
- [ ] 
- [ ] 

## Notes
- 

EOF
    fi
    
    # Todo List Template
    if [ ! -f "$TEMPLATES_DIR/todo.md" ]; then
        cat > "$TEMPLATES_DIR/todo.md" << 'EOF'
# Todo List: {{TITLE}}

**Created:** {{DATE}}

## High Priority
- [ ] 

## Medium Priority
- [ ] 

## Low Priority
- [ ] 

## Completed
- [x] 

EOF
    fi
    
    # Code Snippet Template
    if [ ! -f "$TEMPLATES_DIR/code.md" ]; then
        cat > "$TEMPLATES_DIR/code.md" << 'EOF'
# Code Snippet: {{TITLE}}

**Language:** 
**Purpose:** 

```{{LANG}}
// Your code here
```

## Description
- 

## Usage
```bash
# Example usage
```

EOF
    fi
    
    # Daily Note Template
    if [ ! -f "$TEMPLATES_DIR/daily.md" ]; then
        cat > "$TEMPLATES_DIR/daily.md" << 'EOF'
# Daily Note: {{DATE}}

## Goals for Today
- [ ] 
- [ ] 
- [ ] 

## Tasks Completed
- [x] 

## Notes
- 

## Tomorrow
- 

EOF
    fi
    
    # Journal Template
    if [ ! -f "$TEMPLATES_DIR/journal.md" ]; then
        cat > "$TEMPLATES_DIR/journal.md" << 'EOF'
# Journal Entry: {{DATE}}

## Today's Highlights
- 

## Thoughts
- 

## Gratitude
- 

EOF
    fi
    
    # Habit Tracker Template
    if [ ! -f "$TEMPLATES_DIR/habit_tracker.md" ]; then
        cat > "$TEMPLATES_DIR/habit_tracker.md" << 'EOF'
# Habit Tracker: {{TITLE}}

**Period:** {{DATE}}

## Habits

| Habit | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|-------|-----|-----|-----|-----|-----|-----|-----|
| Exercise | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Reading | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Meditation | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

## Notes
- 

EOF
    fi
    
    # Project Plan Template
    if [ ! -f "$TEMPLATES_DIR/project_plan.md" ]; then
        cat > "$TEMPLATES_DIR/project_plan.md" << 'EOF'
# Project Plan: {{TITLE}}

**Start Date:** {{DATE}}
**Status:** Planning

## Overview
- 

## Goals
- [ ] 
- [ ] 
- [ ] 

## Timeline
- **Week 1:** 
- **Week 2:** 
- **Week 3:** 
- **Week 4:** 

## Resources
- 

## Risks & Challenges
- 

## Notes
- 

EOF
    fi
    
    # Book Review Template
    if [ ! -f "$TEMPLATES_DIR/book_review.md" ]; then
        cat > "$TEMPLATES_DIR/book_review.md" << 'EOF'
# Book Review: {{TITLE}}

**Author:** 
**Date Read:** {{DATE}}
**Rating:** ⭐⭐⭐⭐⭐

## Summary
- 

## Key Takeaways
- 
- 
- 

## Favorite Quotes
> 

## Personal Reflection
- 

EOF
    fi
    
    # Recipe Template
    if [ ! -f "$TEMPLATES_DIR/recipe.md" ]; then
        cat > "$TEMPLATES_DIR/recipe.md" << 'EOF'
# Recipe: {{TITLE}}

**Cuisine:** 
**Prep Time:** 
**Cook Time:** 
**Servings:** 

## Ingredients
- 
- 
- 

## Instructions
1. 
2. 
3. 

## Notes
- 

EOF
    fi
    
    # Interview Notes Template
    if [ ! -f "$TEMPLATES_DIR/interview.md" ]; then
        cat > "$TEMPLATES_DIR/interview.md" << 'EOF'
# Interview Notes: {{TITLE}}

**Date:** {{DATE}}
**Position:** 
**Company:** 
**Interviewer:** 

## Questions Asked
1. 
2. 
3. 

## My Answers
1. 
2. 
3. 

## Notes
- 

## Follow-up
- [ ] Send thank you email
- [ ] 

EOF
    fi
    
    # Weekly Review Template
    if [ ! -f "$TEMPLATES_DIR/weekly_review.md" ]; then
        cat > "$TEMPLATES_DIR/weekly_review.md" << 'EOF'
# Weekly Review: {{DATE}}

## What Went Well
- 
- 
- 

## What Could Be Improved
- 
- 
- 

## Goals for Next Week
- [ ] 
- [ ] 
- [ ] 

## Lessons Learned
- 

EOF
    fi
    
    # Brainstorm Template
    if [ ! -f "$TEMPLATES_DIR/brainstorm.md" ]; then
        cat > "$TEMPLATES_DIR/brainstorm.md" << 'EOF'
# Brainstorm: {{TITLE}}

**Date:** {{DATE}}
**Topic:** 

## Ideas
- 
- 
- 
- 
- 

## Top 3 Ideas
1. 
2. 
3. 

## Action Items
- [ ] 
- [ ] 

EOF
    fi
    
    # Travel Itinerary Template
    if [ ! -f "$TEMPLATES_DIR/travel.md" ]; then
        cat > "$TEMPLATES_DIR/travel.md" << 'EOF'
# Travel Itinerary: {{TITLE}}

**Dates:** {{DATE}}
**Destination:** 

## Day 1
- **Morning:** 
- **Afternoon:** 
- **Evening:** 

## Day 2
- **Morning:** 
- **Afternoon:** 
- **Evening:** 

## Packing List
- [ ] 
- [ ] 
- [ ] 

## Notes
- 

EOF
    fi
    
    # Learning Notes Template
    if [ ! -f "$TEMPLATES_DIR/learning.md" ]; then
        cat > "$TEMPLATES_DIR/learning.md" << 'EOF'
# Learning Notes: {{TITLE}}

**Date:** {{DATE}}
**Source:** 

## Key Concepts
- 
- 
- 

## Examples
```bash
# Code example
```

## Questions
- 
- 

## Summary
- 

EOF
    fi
    
    # Bug Report Template
    if [ ! -f "$TEMPLATES_DIR/bug_report.md" ]; then
        cat > "$TEMPLATES_DIR/bug_report.md" << 'EOF'
# Bug Report: {{TITLE}}

**Date:** {{DATE}}
**Severity:** High/Medium/Low
**Status:** Open

## Description
- 

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
- 

## Actual Behavior
- 

## Environment
- **OS:** 
- **Version:** 

## Screenshots/Logs
- 

EOF
    fi
    
    # Meeting Minutes Template
    if [ ! -f "$TEMPLATES_DIR/meeting_minutes.md" ]; then
        cat > "$TEMPLATES_DIR/meeting_minutes.md" << 'EOF'
# Meeting Minutes: {{TITLE}}

**Date:** {{DATE}}
**Time:** 
**Attendees:** 
- 
- 

## Agenda
1. 
2. 
3. 

## Discussion Points
- 
- 
- 

## Decisions Made
- 
- 

## Action Items
- [ ]  - Owner: 
- [ ]  - Owner: 

## Next Meeting
**Date:** 
**Agenda:** 

EOF
    fi
    
    # Product Review Template
    if [ ! -f "$TEMPLATES_DIR/product_review.md" ]; then
        cat > "$TEMPLATES_DIR/product_review.md" << 'EOF'
# Product Review: {{TITLE}}

**Product:** 
**Date:** {{DATE}}
**Rating:** ⭐⭐⭐⭐⭐

## Pros
- 
- 
- 

## Cons
- 
- 
- 

## Verdict
- 

EOF
    fi
    
    # Workout Log Template
    if [ ! -f "$TEMPLATES_DIR/workout.md" ]; then
        cat > "$TEMPLATES_DIR/workout.md" << 'EOF'
# Workout Log: {{DATE}}

**Type:** 
**Duration:** 
**Intensity:** Low/Medium/High

## Exercises
| Exercise | Sets | Reps | Weight |
|----------|------|------|--------|
| | | | |
| | | | |

## Notes
- 

## Next Session Goals
- 

EOF
    fi
    
    # Budget Template
    if [ ! -f "$TEMPLATES_DIR/budget.md" ]; then
        cat > "$TEMPLATES_DIR/budget.md" << 'EOF'
# Budget: {{TITLE}}

**Period:** {{DATE}}

## Income
| Source | Amount |
|--------|--------|
| | $ |

## Expenses
| Category | Budgeted | Actual |
|----------|----------|--------|
| Food | $ | $ |
| Transport | $ | $ |
| Entertainment | $ | $ |

## Savings Goal
**Target:** $ 
**Current:** $ 

EOF
    fi
    
    # Study Notes Template
    if [ ! -f "$TEMPLATES_DIR/study_notes.md" ]; then
        cat > "$TEMPLATES_DIR/study_notes.md" << 'EOF'
# Study Notes: {{TITLE}}

**Subject:** 
**Date:** {{DATE}}
**Chapter/Topic:** 

## Main Points
- 
- 
- 

## Important Definitions
- **Term:** Definition
- **Term:** Definition

## Examples
- 

## Questions to Review
- 
- 

EOF
    fi
    
    # Event Planning Template
    if [ ! -f "$TEMPLATES_DIR/event_planning.md" ]; then
        cat > "$TEMPLATES_DIR/event_planning.md" << 'EOF'
# Event Planning: {{TITLE}}

**Date:** {{DATE}}
**Location:** 
**Attendees:** 

## Checklist
- [ ] Venue booked
- [ ] Catering arranged
- [ ] Invitations sent
- [ ] Decorations
- [ ] 

## Timeline
- **Before:** 
- **During:** 
- **After:** 

## Budget
- 

## Notes
- 

EOF
    fi
    
    # Goal Setting Template
    if [ ! -f "$TEMPLATES_DIR/goal_setting.md" ]; then
        cat > "$TEMPLATES_DIR/goal_setting.md" << 'EOF'
# Goal Setting: {{TITLE}}

**Date:** {{DATE}}
**Timeline:** 

## Goal
- 

## Why This Goal Matters
- 

## Action Steps
- [ ] 
- [ ] 
- [ ] 

## Milestones
- **Week 1:** 
- **Month 1:** 
- **Month 3:** 

## Obstacles & Solutions
- **Obstacle:** 
  - **Solution:** 

## Progress Tracking
- 

EOF
    fi
    
    # Code Documentation Template
    if [ ! -f "$TEMPLATES_DIR/code_documentation.md" ]; then
        cat > "$TEMPLATES_DIR/code_documentation.md" << 'EOF'
# Code Documentation: {{TITLE}}

**Language:** 
**Date:** {{DATE}}

## Purpose
- 

## Usage
```{{LANG}}
// Example usage
```

## Parameters
- **param1:** Description
- **param2:** Description

## Returns
- 

## Examples
```{{LANG}}
// Example 1
```

## Notes
- 

EOF
    fi
    
    # Research Notes Template
    if [ ! -f "$TEMPLATES_DIR/research.md" ]; then
        cat > "$TEMPLATES_DIR/research.md" << 'EOF'
# Research Notes: {{TITLE}}

**Topic:** 
**Date:** {{DATE}}
**Source:** 

## Key Findings
- 
- 
- 

## Quotes
> 

## References
- 

## Questions
- 
- 

## Next Steps
- 

EOF
    fi
    
    # Standup Notes Template
    if [ ! -f "$TEMPLATES_DIR/standup.md" ]; then
        cat > "$TEMPLATES_DIR/standup.md" << 'EOF'
# Standup Notes: {{DATE}}

## What I Did Yesterday
- 
- 

## What I'm Doing Today
- 
- 

## Blockers
- 

## Notes
- 

EOF
    fi
    
    # Retrospective Template
    if [ ! -f "$TEMPLATES_DIR/retrospective.md" ]; then
        cat > "$TEMPLATES_DIR/retrospective.md" << 'EOF'
# Retrospective: {{TITLE}}

**Date:** {{DATE}}
**Sprint/Period:** 

## What Went Well
- 
- 
- 

## What Didn't Go Well
- 
- 
- 

## What to Try Next
- 
- 
- 

## Action Items
- [ ] 
- [ ] 

EOF
    fi
    
    # Lesson Plan Template
    if [ ! -f "$TEMPLATES_DIR/lesson_plan.md" ]; then
        cat > "$TEMPLATES_DIR/lesson_plan.md" << 'EOF'
# Lesson Plan: {{TITLE}}

**Date:** {{DATE}}
**Duration:** 
**Subject:** 

## Objectives
- 
- 
- 

## Materials Needed
- 
- 

## Lesson Structure
1. **Introduction (5 min):** 
2. **Main Activity (30 min):** 
3. **Conclusion (5 min):** 

## Assessment
- 

## Notes
- 

EOF
    fi
    
    # Client Meeting Template
    if [ ! -f "$TEMPLATES_DIR/client_meeting.md" ]; then
        cat > "$TEMPLATES_DIR/client_meeting.md" << 'EOF'
# Client Meeting: {{TITLE}}

**Date:** {{DATE}}
**Client:** 
**Attendees:** 

## Agenda
1. 
2. 
3. 

## Discussion
- 
- 

## Decisions
- 
- 

## Action Items
- [ ]  - Owner: 
- [ ]  - Owner: 

## Next Steps
- 

EOF
    fi
    
    # Release Notes Template
    if [ ! -f "$TEMPLATES_DIR/release_notes.md" ]; then
        cat > "$TEMPLATES_DIR/release_notes.md" << 'EOF'
# Release Notes: {{TITLE}}

**Version:** 
**Date:** {{DATE}}

## New Features
- 
- 
- 

## Improvements
- 
- 
- 

## Bug Fixes
- 
- 
- 

## Breaking Changes
- 

## Migration Guide
- 

EOF
    fi
    
    # Design Brief Template
    if [ ! -f "$TEMPLATES_DIR/design_brief.md" ]; then
        cat > "$TEMPLATES_DIR/design_brief.md" << 'EOF'
# Design Brief: {{TITLE}}

**Date:** {{DATE}}
**Client/Project:** 

## Objective
- 

## Target Audience
- 

## Requirements
- 
- 
- 

## Constraints
- 

## Inspiration/References
- 

## Timeline
- 

EOF
    fi
    
    # Performance Review Template
    if [ ! -f "$TEMPLATES_DIR/performance_review.md" ]; then
        cat > "$TEMPLATES_DIR/performance_review.md" << 'EOF'
# Performance Review: {{TITLE}}

**Date:** {{DATE}}
**Period:** 
**Reviewer:** 

## Strengths
- 
- 
- 

## Areas for Improvement
- 
- 
- 

## Goals Achieved
- [ ] 
- [ ] 
- [ ] 

## Goals for Next Period
- [ ] 
- [ ] 
- [ ] 

## Notes
- 

EOF
    fi
    
    # Incident Report Template
    if [ ! -f "$TEMPLATES_DIR/incident_report.md" ]; then
        cat > "$TEMPLATES_DIR/incident_report.md" << 'EOF'
# Incident Report: {{TITLE}}

**Date:** {{DATE}}
**Time:** 
**Severity:** Critical/High/Medium/Low

## Description
- 

## Impact
- 

## Timeline
- **Detected:** 
- **Resolved:** 

## Root Cause
- 

## Resolution
- 

## Prevention
- 

EOF
    fi
    
    # Content Outline Template
    if [ ! -f "$TEMPLATES_DIR/content_outline.md" ]; then
        cat > "$TEMPLATES_DIR/content_outline.md" << 'EOF'
# Content Outline: {{TITLE}}

**Type:** Article/Blog/Video
**Date:** {{DATE}}

## Introduction
- 

## Main Points
1. 
2. 
3. 

## Supporting Details
- 
- 

## Conclusion
- 

## Call to Action
- 

EOF
    fi
    
    # Sprint Planning Template
    if [ ! -f "$TEMPLATES_DIR/sprint_planning.md" ]; then
        cat > "$TEMPLATES_DIR/sprint_planning.md" << 'EOF'
# Sprint Planning: {{TITLE}}

**Sprint:** 
**Date:** {{DATE}}
**Duration:** 

## Sprint Goal
- 

## User Stories
- [ ] 
- [ ] 
- [ ] 

## Tasks
- [ ] 
- [ ] 
- [ ] 

## Risks
- 

## Notes
- 

EOF
    fi
}

# List available templates
list_templates() {
    local templates=()
    for template in "$TEMPLATES_DIR"/*.md; do
        [ -f "$template" ] && templates+=("$template")
    done
    
    if [ ${#templates[@]} -eq 0 ]; then
        echo ""
        return 1
    fi
    
    printf '%s\n' "${templates[@]}"
}

# Get template content
# Usage: get_template template_name
get_template() {
    local template_name="$1"
    local template_file="$TEMPLATES_DIR/${template_name}.md"
    
    if [ ! -f "$template_file" ]; then
        return 1
    fi
    
    cat "$template_file"
}

# Process template variables
# Usage: process_template template_content [title] [date]
process_template() {
    local content="$1"
    local title="${2:-New Note}"
    local date_str="${3:-$(date '+%Y-%m-%d')}"
    
    echo "$content" | sed "s/{{TITLE}}/$title/g" | sed "s/{{DATE}}/$date_str/g" | sed "s/{{LANG}}/bash/g"
}

# Create note from template
# Usage: create_from_template template_name [note_title]
create_from_template() {
    local template_name="$1"
    local note_title="${2:-}"
    
    init_templates
    
    local template_content=$(get_template "$template_name")
    if [ $? -ne 0 ]; then
        send_notification "Notes App" "Template not found: $template_name"
        return 1
    fi
    
    if [ -z "$note_title" ]; then
        echo -e "${YELLOW}Enter note title:${RESET}"
        read -r note_title
        if [ -z "$note_title" ]; then
            send_notification "Notes App" "Note creation cancelled"
            return 1
        fi
    fi
    
    local processed_content=$(process_template "$template_content" "$note_title")
    local filename=$(echo "$note_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    local filepath="$NOTES_DIR/${filename}.md"
    
    if [ -f "$filepath" ]; then
        local timestamp=$(date +%s)
        filepath="$NOTES_DIR/${filename}_${timestamp}.md"
    fi
    
    echo "$processed_content" > "$filepath"
    send_notification "Notes App" "Note created from template: $note_title"
    CURRENT_NOTE="$filepath"
    preview_note "$filepath"
    return 0
}

# Template selection menu
template_menu() {
    init_templates
    
    local templates=()
    for template in "$TEMPLATES_DIR"/*.md; do
        [ -f "$template" ] && templates+=("$template")
    done
    
    if [ ${#templates[@]} -eq 0 ]; then
        clear
        echo -e "${DIM}No templates available${RESET}\n"
        read -rsn1
        return
    fi
    
    local selected_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     SELECT TEMPLATE${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        
        for i in "${!templates[@]}"; do
            local template="${templates[$i]}"
            local name=$(basename "$template" .md)
            local display_name=$(echo "$name" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
            
            if [ $i -eq $selected_index ]; then
                echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${display_name}${RESET}"
            else
                echo -e "     ${YELLOW}[$((i+1))]${RESET} ${display_name}"
            fi
        done
        
        echo ""
        echo -e "${PURPLE}[ENTER]${RESET} Select    ${PURPLE}[ESC]${RESET} Cancel"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#templates[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#templates[@]})) && selected_index=0
                ;;
            "")
                if [ ${#templates[@]} -gt 0 ]; then
                    local selected_template="${templates[$selected_index]}"
                    local template_name=$(basename "$selected_template" .md)
                    create_from_template "$template_name"
                    return
                fi
                ;;
            [0-9])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#templates[@]} ]; then
                    local selected_template="${templates[$index]}"
                    local template_name=$(basename "$selected_template" .md)
                    create_from_template "$template_name"
                    return
                fi
                ;;
        esac
    done
}

# Create daily note
create_daily_note() {
    local date_str=$(date '+%Y-%m-%d')
    local filename="daily-${date_str}.md"
    local filepath="$NOTES_DIR/$filename"
    
    if [ -f "$filepath" ]; then
        preview_note "$filepath"
        return
    fi
    
    create_from_template "daily" "Daily Note - $date_str"
}

