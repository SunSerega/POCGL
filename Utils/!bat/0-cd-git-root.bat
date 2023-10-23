FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
	SET git_root=%%F
)
cd %git_root%