from datetime import datetime, timedelta
from dateutil import tz
import os

import argparse
import pandas as pd

from basketball_reference_web_scraper import client
from basketball_reference_web_scraper.data import Team

_FROM_ZONE = tz.gettz('UTC')
_TO_ZONE = tz.gettz('America/New_York')


def _convert_time_from_utc(dt: datetime) -> datetime:
    return dt.replace(tzinfo=_FROM_ZONE).astimezone(_TO_ZONE)


def process_play_by_play(*, year: int, output_dir: str) -> None:
    sched = client.season_schedule(season_end_year=year)

    for game in sched:
        home_team = game['home_team'].name
        start_time = _convert_time_from_utc(game['start_time'])
        start_time_str = start_time.strftime('%Y-%m-%d')
        print(f"[{start_time_str}]: Pulling data for home team {home_team}")

        play_by_play = client.play_by_play(
            home_team=game['home_team'],
            year=start_time.year,
            month=start_time.month,
            day=start_time.day,
        )
        for play in play_by_play:
            play['date'] = start_time_str
            play['period_type'] = play['period_type'].name
            play['away_team'] = play['away_team'].name
            play['home_team'] = play['home_team'].name

        output_filename = f"game_date={start_time_str}_hometeam={home_team}.tsv"
        pd.DataFrame.from_records(play_by_play).to_csv(
            os.path.join(output_dir, output_filename),
            header=True,
            index=False,
            sep='\t',
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Options for fetching play-by-play data.')
    parser.add_argument('--year', type=int, help='season_end_year')
    parser.add_argument('--outputdir', help='place to dump game files', required=True)

    args = parser.parse_args()

    process_play_by_play(year=args.year, output_dir=args.outputdir)
