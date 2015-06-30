import glob, os
debug = 0

for image in glob.glob('*.jpg'):
	os.system('aws s3 cp ' + image + ' s3://stelligent-demo/images/ && rm -fv image')

