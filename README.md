To get the Python environment ready, first create a new conda env:

> conda create --name freethrows python=3.6
> source activate freethrows
> pip install -r requirements.txt

In order to download a year of data, simply run

> python src/fetch_play_by_play.py --outputdir='./data/2019' --year=2019

Make sure you have created ./data/2019 first.
