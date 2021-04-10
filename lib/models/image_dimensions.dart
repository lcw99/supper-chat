class ImageDimensions {
  int? width;
  int? height;

  ImageDimensions({this.width, this.height});

  ImageDimensions.fromMap(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['width'] = this.width;
    data['height'] = this.height;
    return data;
  }

  @override
  String toString() {
    return '{"width": "$width", "height": "$height"}';
  }

}