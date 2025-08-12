class FilterCriteria {
  String? name;
  String? email;
  String? phone;
  String? business;
  String? city;
  int? status;

  FilterCriteria({
    this.name,
    this.email,
    this.phone,
    this.business,
    this.city,
    this.status,
  });

  bool isEmpty() {
    return name?.isEmpty != false &&
        email?.isEmpty != false &&
        phone?.isEmpty != false &&
        business?.isEmpty != false &&
        city?.isEmpty != false &&
        status == null;
  }

  void clear() {
    name = null;
    email = null;
    phone = null;
    business = null;
    city = null;
    status = null;
  }
}
