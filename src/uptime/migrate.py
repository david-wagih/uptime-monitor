"""Create database tables. Runs as a one-shot step before the api and worker start."""

from uptime import models  # noqa: F401  (registers the tables on Base.metadata)
from uptime.db import Base, engine


def main() -> None:
    Base.metadata.create_all(engine)
    print("database schema is up to date")


if __name__ == "__main__":
    main()
