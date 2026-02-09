# Bug Reports

This directory contains bug reports for the HeadsUp platform.

## File Naming Convention

`BUG-[number].md` - Sequential bug numbers

## Bug Status

- **Open** - Bug reported, not yet investigated
- **Investigating** - Bug being analyzed
- **Documented** - Bug has full documentation with user stories and test cases
- **In Progress** - Fix being implemented
- **Fixed** - Fix complete, awaiting verification
- **Verified** - Fix verified, tests passing
- **Closed** - Bug resolved and deployed

## Using /bug-fix Command

To process a bug through the full workflow:

```bash
/bug-fix BUGS/BUG-1.md
```

This will:
1. Investigate the bug and find related user stories/test cases
2. Enrich the bug documentation
3. Implement the fix using headsup-implementer
4. Add tests using headsup-tester

## Bug Template

See `TEMPLATE.md` for the recommended bug report format.
