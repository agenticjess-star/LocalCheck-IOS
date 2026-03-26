Fix a bug or issue in LocalCheck. $ARGUMENTS

Steps:
1. **Understand**: Read the relevant source files to understand current behavior
2. **Identify**: Locate the root cause — don't just patch symptoms
3. **Plan**: Describe the fix before implementing
4. **Implement**: Make the minimal change needed
5. **Verify**: Build the project to ensure no compile errors
6. **Report**: Summarize what was wrong and what you changed

Rules:
- Keep changes minimal and focused
- Don't refactor surrounding code
- Don't add features beyond the fix
- If the fix touches AppState, check that all views using the affected data still work
