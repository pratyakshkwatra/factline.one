import logging
import sys

# ANSI Color codes for clean terminal output
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"

LEVEL_COLORS = {
    logging.DEBUG: MAGENTA,
    logging.INFO: GREEN,
    logging.WARNING: YELLOW,
    logging.ERROR: RED,
    logging.CRITICAL: BOLD + RED,
}

class FactlineLogFormatter(logging.Formatter):
    def format(self, record):
        color = LEVEL_COLORS.get(record.levelno, RESET)
        asctime = self.formatTime(record, "%Y-%m-%d %H:%M:%S")
        level_name = f"{color}{record.levelname:<7}{RESET}"
        name = f"{CYAN}[{record.name}]{RESET}"
        message = record.getMessage()
        return f"{DIM}{asctime}{RESET} {level_name} {name} {message}"

def get_logger(name: str) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(FactlineLogFormatter())
        logger.addHandler(handler)
        logger.propagate = False
    return logger

