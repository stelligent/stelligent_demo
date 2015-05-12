import os, re
from pprint import pprint
from inspect import getmembers
from instagram.client import InstagramAPI
debug = 0

with open ("/var/lib/jenkins/.instagram.client.id", "r") as envId:
    	clientId = re.sub(r'\W+', '', envId.read())

with open ("/var/lib/jenkins/.instagram.client.secret", "r") as envSecret:
    	clientSecret = re.sub(r'\W+', '', envSecret.read())

api = InstagramAPI(client_id=clientId,client_secret=clientSecret)
popular_media = api.media_popular(count=1)
for media in popular_media:
        imageFile = media.id + ".jpg";
	os.system('wget -O %s.jpg %s' % (media.id, media.images['thumbnail'].url) )
	if debug == 1: pprint(getmembers(media))


