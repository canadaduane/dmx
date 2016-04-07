# Run this inside the container:
cd /root/mxnet/samples/neural-style
python run.py \
  --style-image images/vivian-coloring-small.jpg  \
  --content-image images/vivian.jpg \
  --output images/vivian-art10.jpg \
  --stop-eps 0.001 \
  --remove-noise 0.1 \
  --style-weight 2.0
