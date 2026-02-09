# Project Overview

## Project Name

HeadsUp (GoalHub working name)

## One-Line Description

A goal-first social network that helps goal creators, accountability partners, and coaches to set structured goals and challenges, track progress, and stay accountable socially.

## Problem Statement

### The Problem

People struggle to stay consistent with goals because planning, tracking, and social accountability are fragmented across tools.

### Current Solutions

Users juggle notes, habit trackers, and social apps, or try to self-manage without structured plans or accountability.

### Why They're Not Good Enough

Most tools lack a structured, social, and goal-centric workflow that connects planning (phases/steps) with real-time accountability.

## Success Criteria

How do we know this project is successful?

- [ ] Users can create structured goals with phases/steps and track progress
- [ ] Users can join or create challenges and see scheduled tasks
- [ ] Coaches can run group goals and monitor participant progress

## Scope

### In Scope (MVP)

- Goals with phases/steps, progress tracking, and goal feed
- Challenges (predefined + custom with scheduling)
- Coach Center (group goals + dashboard)

### Out of Scope (Future)

- Payments / monetization
- Maps / location features
- Advanced analytics and AI/ML features

## Technical Constraints

- Runtime: Elixir ~> 1.14 — see `/project_doc/specifications/tech-stack.md`
- Must deploy to: Docker-ready with Bandit HTTP server — see `/project_doc/specifications/deployment-infra.md`
- Must support: Modern browsers (last 2 versions of Chrome, Firefox, Safari, Edge) — see `/project_doc/specifications/nfr.md`
- Database: PostgreSQL via Ecto — see `/project_doc/specifications/tech-stack.md`

## Non-Functional Requirements Summary

Key NFR targets (full details in `/project_doc/specifications/nfr.md`):

- **Performance:** API p95 < 200ms, LCP < 2.5s
- **Security:** OWASP Top 10 mitigated, ownership checks and session-based auth
- **Accessibility:** WCAG 2.1 AA
- **Uptime:** 99.9% SLA (target)
- **Compliance:** GDPR/CCPA later; none required for MVP

## Timeline

- Target MVP completion: As soon as possible
