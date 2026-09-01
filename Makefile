CC       := gcc
CSTD     := -std=c11
WARN     := -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wunused-parameter
OPT      := -O2
DEBUG    := -g

CFLAGS   := $(CSTD) $(WARN) $(OPT) $(DEBUG) -Iinclude -pthread
LDFLAGS  := -pthread

# Strict, MISRA-oriented profile used by `make misra`.
MISRA_CFLAGS := $(CSTD) $(WARN) -fanalyzer -Iinclude -pthread

SRC_DIR  := src
TEST_DIR := tests
OBJ_DIR  := build
TARGET   := bank

SOURCES     := $(wildcard $(SRC_DIR)/*.c)
OBJECTS     := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SOURCES))
LIB_SOURCES := $(filter-out $(SRC_DIR)/main.c,$(SOURCES))

TEST_SOURCES := $(wildcard $(TEST_DIR)/*.c)
TEST_BIN     := test_runner

COVERAGE_DIR := $(OBJ_DIR)/coverage
COVERAGE_BIN := bank_coverage
COVERAGE_TEST_BIN := test_runner_coverage
COVERAGE_TEST_OBJ_DIR := $(COVERAGE_DIR)/test_obj
COVERAGE_MIN := 95

.PHONY: all clean run dirs test smoke valgrind helgrind cppcheck misra coverage

all: dirs $(TARGET)

dirs:
	@mkdir -p $(OBJ_DIR) database

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

run: all
	./$(TARGET)

# ============================================================
# UNIT / INTEGRATION TESTING
#
# No --coverage is used here.
# Therefore this target does not create .gcda/.gcno files.
# ============================================================

test: dirs
	@echo "=========================================="
	@echo " Running Unit / Integration Tests"
	@echo "=========================================="
	@rm -f $(TEST_BIN)
	@rm -rf database
	@mkdir -p database

	$(CC) $(CSTD) -Wall -Wextra -g -O0 \
		-Iinclude -I$(TEST_DIR) -pthread \
		$(LIB_SOURCES) $(TEST_SOURCES) \
		-o $(TEST_BIN) -lcunit -pthread

	./$(TEST_BIN)

	@rm -f $(TEST_BIN)
	@echo ""
	@echo "=========================================="
	@echo " Unit / Integration Tests Passed"
	@echo "=========================================="

# ============================================================
# SMOKE TEST
# ============================================================

smoke: all
	@rm -rf database
	./$(TARGET) < $(TEST_DIR)/smoke_input.txt
	@echo "Smoke test completed successfully."

# ============================================================
# VALGRIND
# ============================================================

valgrind:
	@mkdir -p database
	$(CC) $(CSTD) -Wall -Wextra -g -O0 \
		-Iinclude -pthread \
		$(LIB_SOURCES) $(SRC_DIR)/main.c \
		-o $(TARGET)_dbg -pthread
	@rm -rf database
	valgrind --leak-check=full \
		--show-leak-kinds=all \
		--track-origins=yes \
		--error-exitcode=99 \
		./$(TARGET)_dbg < $(TEST_DIR)/valgrind_input.txt

# ============================================================
# HELGRIND (THREAD ERROR DETECTION)
# ============================================================

helgrind:
	@mkdir -p database
	$(CC) $(CSTD) -Wall -Wextra -g -O0 \
		-Iinclude -pthread \
		$(LIB_SOURCES) $(SRC_DIR)/main.c \
		-o $(TARGET)_dbg -pthread
	@rm -rf database
	valgrind --tool=helgrind \
		--error-exitcode=99 \
		./$(TARGET)_dbg < $(TEST_DIR)/valgrind_input.txt

# ============================================================
# CPPCHECK
# ============================================================

cppcheck:
	cppcheck --enable=all \
		--std=c11 \
		--suppress=missingIncludeSystem \
		-Iinclude \
		$(SRC_DIR)

	cppcheck --enable=all \
		--std=c11 \
		--check-config \
		--suppress=missingIncludeSystem \
		-Iinclude \
		$(SRC_DIR)

# ============================================================
# MISRA-ORIENTED COMPILATION
# ============================================================

misra:
	$(CC) $(MISRA_CFLAGS) \
		$(SOURCES) \
		-o $(TARGET)_misra_check \
		-pthread

# ============================================================
# CODE COVERAGE
#
# This is independent of CUnit.
# It does NOT run `make test`.
# It builds the actual application with --coverage, runs the scripted
# application journeys, then runs the CUnit suite against the same
# instrumented application objects. Only src/ files are reported.
#
# Temporary .gcda/.gcno/.gcov files are removed after the report.
# ============================================================

COVERAGE_OBJ_DIR := $(COVERAGE_DIR)/obj
COVERAGE_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(COVERAGE_OBJ_DIR)/%.o,$(SOURCES))
COVERAGE_LIB_OBJECTS := $(filter-out $(COVERAGE_OBJ_DIR)/main.o,$(COVERAGE_OBJECTS))

coverage: dirs
	@echo "=========================================="
	@echo " Building Application for Code Coverage"
	@echo "=========================================="

	@rm -rf $(COVERAGE_DIR)
	@mkdir -p $(COVERAGE_DIR) $(COVERAGE_OBJ_DIR) $(COVERAGE_TEST_OBJ_DIR)
	@rm -f $(COVERAGE_BIN)
	@rm -f $(COVERAGE_TEST_BIN)
	@rm -f *.gcda *.gcno *.gcov
	@rm -f $(SRC_DIR)/*.gcda $(SRC_DIR)/*.gcno $(SRC_DIR)/*.gcov
	@rm -rf database
	@mkdir -p database

	@for file in $(SOURCES); do \
		base=$$(basename "$$file" .c); \
		$(CC) $(CSTD) $(WARN) -O0 -g \
			--coverage \
			-Iinclude -pthread \
			-c "$$file" -o "$(COVERAGE_OBJ_DIR)/$$base.o" || exit 1; \
	done
	$(CC) --coverage $(COVERAGE_OBJ_DIR)/*.o -o $(COVERAGE_BIN) -pthread

	@if [ ! -f $(TEST_DIR)/run_coverage_passes.sh ]; then \
		echo "ERROR: $(TEST_DIR)/run_coverage_passes.sh not found."; \
		rm -f $(COVERAGE_BIN); \
		exit 1; \
	fi

	@echo ""
	@echo "=========================================="
	@echo " Running Application for Code Coverage"
	@echo "=========================================="
	@echo " Running a sequence of targeted input"
	@echo " fixtures (tests/coverage_fixtures/) against"
	@echo " a single instrumented binary; gcov merges"
	@echo " coverage counts across all passes. See"
	@echo " tests/run_coverage_passes.sh for details."
	@echo "=========================================="

	bash $(TEST_DIR)/run_coverage_passes.sh ./$(COVERAGE_BIN)

	@echo ""
	@echo "=========================================="
	@echo " Running Unit / Integration Tests for Coverage"
	@echo "=========================================="
	@for file in $(TEST_SOURCES); do \
		base=$$(basename "$$file" .c); \
		$(CC) $(CSTD) $(WARN) -O0 -g \
			-Iinclude -I$(TEST_DIR) -pthread \
			-c "$$file" -o "$(COVERAGE_TEST_OBJ_DIR)/$$base.o" || exit 1; \
	done
	$(CC) --coverage $(COVERAGE_LIB_OBJECTS) $(COVERAGE_TEST_OBJ_DIR)/*.o \
		-o $(COVERAGE_TEST_BIN) -lcunit -pthread
	./$(COVERAGE_TEST_BIN)

	@echo ""
	@echo "=========================================="
	@echo " Generating Coverage Report"
	@echo "=========================================="

	@for file in $(SOURCES); do \
		gcov -b -c -o $(COVERAGE_OBJ_DIR) "$$file" >> $(COVERAGE_DIR)/summary.txt 2>&1 || true; \
	done

	@mv -f *.gcov $(COVERAGE_DIR)/ 2>/dev/null || true

	@echo ""
	@echo "========== COVERAGE SUMMARY (per file) =========="
	@grep -E "File|Lines executed|Branches executed|Taken at least once" \
		$(COVERAGE_DIR)/summary.txt || true

	@echo ""
	@echo "========== COVERAGE SUMMARY (overall) =========="
	@awk -F'[:% ]+' '/^Lines executed/{le+=$$3*$$5/100; lt+=$$5} \
		/^Branches executed/{be+=$$3*$$5/100; bt+=$$5} \
		END { \
			if (lt>0) printf "Overall line coverage:    %.2f%% (%d/%d lines)\n", le/lt*100, le, lt; \
			if (bt>0) printf "Overall branch coverage:  %.2f%% (%d/%d branches)\n", be/bt*100, be, bt; \
		}' $(COVERAGE_DIR)/summary.txt

	@rm -rf $(COVERAGE_OBJ_DIR) $(COVERAGE_TEST_OBJ_DIR)
	@rm -f $(COVERAGE_BIN) $(COVERAGE_TEST_BIN)
	@rm -f *.gcda *.gcno *.gcov
	@rm -f $(SRC_DIR)/*.gcda $(SRC_DIR)/*.gcno $(SRC_DIR)/*.gcov

	@echo ""
	@echo "Coverage report: $(COVERAGE_DIR)/summary.txt"
	@echo "Temporary coverage files removed."
	@line_coverage=$$(awk -F'[:% ]+' '/^Lines executed/{le+=$$3*$$5/100; lt+=$$5} \
		END {if (lt>0) printf "%.2f", le/lt*100; else print "0.00"}' \
		$(COVERAGE_DIR)/summary.txt); \
	

# ============================================================
# CLEAN
# ============================================================

clean:
	rm -rf $(OBJ_DIR) \
		$(TARGET) \
		$(TARGET)_dbg \
		$(TARGET)_misra_check \
		$(TEST_BIN) \
		$(COVERAGE_BIN) \
		$(COVERAGE_TEST_BIN) \
		database \
		*.gcda *.gcno *.gcov \
		$(SRC_DIR)/*.gcda \
		$(SRC_DIR)/*.gcno \
		$(SRC_DIR)/*.gcov
