class Category
{
  String? id;
  String? categoryName;
  String? categoryImg;

  Category({this.id, this.categoryName, this.categoryImg});

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['category_name'];
    categoryImg = json['category_img'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['category_name'] = this.categoryName;
    data['category_img'] = this.categoryImg;
    return data;
  }
}