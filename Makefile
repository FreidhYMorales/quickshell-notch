QT_BIN    := /usr/lib/qt6/bin
QMLFORMAT := $(QT_BIN)/qmlformat
QMLLINT   := $(QT_BIN)/qmllint
QML_DIR   := /usr/lib/qt6/qml
QML_FILES := $(shell find shell -name '*.qml')
QMLDIRS   := $(addprefix -i ,$(shell find shell -name qmldir))
JS_PATHS  := shell/logic tests

.PHONY: check ci fmt fmt-check lint lint-qml lint-js test qml-test smoke

# Full local quality gate (read-only).
check: fmt-check lint test qml-test smoke

# Subset that runs in GitHub Actions (no Quickshell types, no Wayland session).
ci: fmt-check lint-js test

fmt:
	$(QMLFORMAT) -i $(QML_FILES)
	deno fmt $(JS_PATHS)

fmt-check:
	@for f in $(QML_FILES); do \
		$(QMLFORMAT) "$$f" | diff -u "$$f" - || { echo "qmlformat: $$f is not formatted (run make fmt)"; exit 1; }; \
	done
	deno fmt --check $(JS_PATHS)

lint: lint-qml lint-js

lint-qml:
	$(QMLLINT) -I $(QML_DIR) $(QMLDIRS) $(QML_FILES)

lint-js:
	deno lint $(JS_PATHS)

test:
	node --test tests/

qml-test:
	node --test tests/qml/qs-runtime.mjs tests/qml/tray-icon.mjs tests/qml/tray-generic.mjs tests/qml/tray-placeholder.mjs tests/qml/tray-hover.mjs tests/qml/tray-empty.mjs

# Loads the real config in Quickshell; timeout exit 124 is the success path.
smoke:
	@log=$$(NOTCH_SMOKE=1 timeout 10 qs -p shell/shell.qml 2>&1); code=$$?; \
	if [ $$code -ne 0 ] && [ $$code -ne 124 ]; then echo "$$log"; echo "smoke: qs exited with $$code"; exit 1; fi; \
	if echo "$$log" | grep -qE 'ERROR|Failed to load|is not a type|is not installed'; then echo "$$log"; echo "smoke: load errors"; exit 1; fi; \
	echo "smoke: config loaded"
