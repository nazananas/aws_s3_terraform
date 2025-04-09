locals {
  image_files = fileset("${path.module}/images", "*.{png,jpg,jpeg}")
}
