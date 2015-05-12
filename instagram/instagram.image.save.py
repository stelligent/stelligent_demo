import glob
debug = 0

for image in glob.glob('*.jpg'):
	os.system('aws s3 cp ' + image + ' s3://nando-automation-demo/images/ && rm -fv image') 

