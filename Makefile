QT_BIN    := /usr/lib/qt6/bin
QMLFORMAT := $(QT_BIN)/qmlformat
QMLLINT   := $(QT_BIN)/qmllint
QML_DIR   := /usr/lib/qt6/qml
QML_FILES := $(shell find shell -name '*.qml')
QMLDIRS   := $(addprefix -i ,$(shell find shell -name qmldir))
JS_PATHS  := shell/logic tests
THEME_PROBES := $(wildcard tests/qml/theme-*.mjs)
# Probes that open the launcher and press keys need the keyboard to
# themselves, so they cannot share the parallel theme run.
THEME_KEYS := tests/qml/theme-back.mjs tests/qml/theme-keys.mjs
# Deployment tree for the greetd greeter; the file list lives in greetd/tree.txt.
GREETER_DEST ?= /usr/local/share/quickshell-notch-greetd

.PHONY: check ci fmt fmt-check lint lint-qml lint-js test qml-test smoke deploy-greeter

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
	node --test tests/qml/sddm-timeout.mjs
	node --test tests/qml/greetd-preview.mjs
	node --test tests/qml/greetd-protocol.mjs
	node --test tests/qml/greetd-real.mjs
	node --test tests/qml/tray-runner-safety.mjs tests/qml/other-runners-safety.mjs
	node --test tests/qml/tray-menu-fixture.mjs tests/qml/tray-menu-entry.mjs
	node --test tests/qml/tray-menu-open.mjs tests/qml/tray-menu-size.mjs tests/qml/tray-menu-activate.mjs tests/qml/tray-menu-disabled.mjs tests/qml/tray-menu-separator.mjs
	node --test tests/qml/tray-menu-look.mjs tests/qml/tray-menu-hover.mjs tests/qml/tray-menu-toggle.mjs tests/qml/tray-menu-leave.mjs
	node --test tests/qml/tray-menu-scroll.mjs tests/qml/tray-menu-indicator.mjs tests/qml/tray-menu-header.mjs
	node --test tests/qml/tray-menu-width.mjs tests/qml/tray-menu-checkmark.mjs tests/qml/tray-menu-app-separator.mjs
	node --test tests/qml/qs-runtime.mjs tests/qml/tray-icon.mjs tests/qml/tray-generic.mjs tests/qml/tray-placeholder.mjs tests/qml/tray-hover.mjs tests/qml/tray-empty.mjs tests/qml/tray-switch.mjs tests/qml/tray-activate.mjs tests/qml/tray-close.mjs tests/qml/tray-closing-priority.mjs tests/qml/tray-open-priority.mjs tests/qml/tray-divider.mjs tests/qml/tray-icon-size.mjs tests/qml/tray-image-error.mjs tests/qml/tray-image-ready.mjs tests/qml/tray-multiple.mjs
	node --test tests/qml/recording-*.mjs
	node --test tests/qml/power-*.mjs
	node --test tests/qml/wallpaper-*.mjs tests/qml/caffeine-*.mjs tests/qml/idle-*.mjs tests/qml/sleep-*.mjs tests/qml/controlcenter-*.mjs tests/qml/expanded-*.mjs $(filter-out $(THEME_KEYS),$(THEME_PROBES))
	# Serial: lock screen probes take the keyboard.
	node --test --test-concurrency=1 tests/qml/lock-*.mjs
	# Serial: polkit probes can take the exclusive keyboard.
	node --test --test-concurrency=1 tests/qml/polkit-*.mjs
	# Serial: each launcher probe takes the exclusive keyboard.
	node --test --test-concurrency=1 tests/qml/launcher-*.mjs
	# Serial: the launcher-driven theme probes press keys too.
	node --test --test-concurrency=1 $(THEME_KEYS)

# Installs the greeter tree that greetd runs. Needs root:
#   sudo make deploy-greeter
# The list of deployed files is greetd/tree.txt, the same one the greeter test
# copies into a temporary tree.
deploy-greeter:
	install -d $(GREETER_DEST)
	chmod 0755 $(GREETER_DEST)
	@while IFS= read -r file; do \
		case "$$file" in ""|\#*) continue;; esac; \
		install -D -m 0644 "$$file" "$(GREETER_DEST)/$$file" || exit 1; \
	done < greetd/tree.txt
	install -D -m 0755 greetd/launch-greeter.sh $(GREETER_DEST)/greetd/launch-greeter.sh
	@echo "greeter tree installed in $(GREETER_DEST)"

# Loads the real config in Quickshell; timeout exit 124 is the success path.
smoke:
	@log=$$(QS_DISABLE_CRASH_HANDLER=1 NOTCH_SMOKE=1 timeout 10 qs -p shell/shell.qml 2>&1); code=$$?; \
	if [ $$code -ne 0 ] && [ $$code -ne 124 ]; then echo "$$log"; echo "smoke: qs exited with $$code"; exit 1; fi; \
	if echo "$$log" | grep -qE 'ERROR|Failed to load|is not a type|is not installed'; then echo "$$log"; echo "smoke: load errors"; exit 1; fi; \
	echo "smoke: config loaded"
