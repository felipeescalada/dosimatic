import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../models/filter_model.dart';
import '../services/contact_service.dart';
import 'contact_form_screen.dart';
import '../widgets/app_drawer.dart';

class ContactListScreen1 extends StatefulWidget {
  final int version;
  final String title;

  const ContactListScreen1({
    super.key,
    this.version = 0,
    this.title = 'Contact  0001 ',
  });

  @override
  State<ContactListScreen1> createState() => _ContactListScreenState1();
}

class _ContactListScreenState1 extends State<ContactListScreen1> {
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _emailFilterController = TextEditingController();
  final TextEditingController _phoneFilterController = TextEditingController();
  final TextEditingController _businessFilterController =
      TextEditingController();
  final TextEditingController _cityFilterController = TextEditingController();
  int _rowsPerPage = 10;
  FilterCriteria _filterCriteria = FilterCriteria();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    _emailFilterController.dispose();
    _phoneFilterController.dispose();
    _businessFilterController.dispose();
    _cityFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await ContactService.getContacts(
        page: 1,
        limit: 50,
        status: 1,
      );
      if (!mounted) return;

      setState(() {
        _allContacts = contacts;
        _filteredContacts = List.from(_allContacts);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contacts: $e')),
      );
    }
  }

  void _sort<T>(Comparable<T> Function(Contact contact) getField,
      int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _filteredContacts.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        bool matchesName = _filterCriteria.name?.isEmpty ?? true;
        bool matchesEmail = _filterCriteria.email?.isEmpty ?? true;
        bool matchesPhone = _filterCriteria.phone?.isEmpty ?? true;
        bool matchesBusiness = _filterCriteria.business?.isEmpty ?? true;
        bool matchesCity = _filterCriteria.city?.isEmpty ?? true;
        bool matchesStatus = _filterCriteria.status == null;

        if (_filterCriteria.name?.isNotEmpty ?? false) {
          matchesName = contact.fullName
              .toLowerCase()
              .contains(_filterCriteria.name!.toLowerCase());
        }

        if (_filterCriteria.email?.isNotEmpty ?? false) {
          matchesEmail = contact.email
              .toLowerCase()
              .contains(_filterCriteria.email!.toLowerCase());
        }

        if (_filterCriteria.phone?.isNotEmpty ?? false) {
          matchesPhone = contact.phoneNumber
              .toLowerCase()
              .contains(_filterCriteria.phone!.toLowerCase());
        }

        if (_filterCriteria.business?.isNotEmpty ?? false) {
          matchesBusiness = contact.businessName
              .toLowerCase()
              .contains(_filterCriteria.business!.toLowerCase());
        }

        if (_filterCriteria.city?.isNotEmpty ?? false) {
          matchesCity = contact.city
              .toString()
              .toLowerCase()
              .contains(_filterCriteria.city!.toLowerCase());
        }

        if (_filterCriteria.status != null) {
          matchesStatus = contact.status == _filterCriteria.status;
        }

        return matchesName &&
            matchesEmail &&
            matchesPhone &&
            matchesBusiness &&
            matchesCity &&
            matchesStatus;
      }).toList();
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Advanced Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameFilterController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (value) => _filterCriteria.name = value,
                ),
                TextField(
                  controller: _emailFilterController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) => _filterCriteria.email = value,
                ),
                TextField(
                  controller: _phoneFilterController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onChanged: (value) => _filterCriteria.phone = value,
                ),
                TextField(
                  controller: _businessFilterController,
                  decoration: const InputDecoration(labelText: 'Business'),
                  onChanged: (value) => _filterCriteria.business = value,
                ),
                TextField(
                  controller: _cityFilterController,
                  decoration: const InputDecoration(labelText: 'City'),
                  onChanged: (value) => _filterCriteria.city = value,
                ),
                DropdownButtonFormField<int>(
                  value: _filterCriteria.status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 1, child: Text('Active')),
                    DropdownMenuItem(value: 0, child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterCriteria.status = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: PaginatedDataTable(
                header: const Text('Contacts'),
                rowsPerPage: _rowsPerPage,
                availableRowsPerPage: const [10, 20, 50],
                onRowsPerPageChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                  });
                },
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(
                    label: const Text('ID'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.idContact,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.fullName,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Phone'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.phoneNumber,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Email'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.email,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Business'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.businessName,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('City'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.city.toString(),
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Country'),
                    onSort: (columnIndex, ascending) {
                      _sort<String>(
                        (contact) => contact.country.toString(),
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  DataColumn(
                    label: const Text('Created At'),
                    onSort: (columnIndex, ascending) {
                      _sort<DateTime>(
                        (contact) => contact.createdAt,
                        columnIndex,
                        ascending,
                      );
                    },
                  ),
                  const DataColumn(
                    label: Text('Actions'),
                  ),
                ],
                source: _ContactDataSource(
                  _filteredContacts,
                  context,
                  (contact, isModal) async {
                    Contact? updatedContact;
                    if (isModal) {
                      updatedContact = await showDialog<Contact>(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.height * 0.8,
                              padding: const EdgeInsets.all(8.0),
                              child: ContactFormScreen(contact: contact),
                            ),
                          );
                        },
                      );
                    } else {
                      updatedContact = await Navigator.push<Contact>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactFormScreen(
                            contact: contact,
                          ),
                        ),
                      );
                    }
                    if (updatedContact != null) {
                      setState(() {
                        final index = _allContacts.indexWhere(
                            (c) => c.idContact == contact.idContact);
                        if (index != -1) {
                          _allContacts[index] = updatedContact!;
                          _applyFilters();
                        }
                      });
                    }
                  },
                ),
              ),
            ),
    );
  }
}

class _ContactDataSource extends DataTableSource {
  final List<Contact> _contacts;
  final BuildContext context;
  final void Function(Contact, bool) onEdit;

  _ContactDataSource(this._contacts, this.context, this.onEdit);

  @override
  DataRow getRow(int index) {
    final contact = _contacts[index];
    return DataRow(
      cells: [
        DataCell(Text(contact.idContact)),
        DataCell(Text('${contact.firstName} ${contact.lastName}')),
        DataCell(Text(contact.phoneNumber)),
        DataCell(Text(contact.email)),
        DataCell(Text(contact.businessName)),
        DataCell(Text(contact.city.toString())),
        DataCell(Text(contact.country.toString())),
        DataCell(Text(DateFormat('dd/MM/yyyy').format(contact.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => onEdit(contact, false),
                tooltip: 'Edit in new page',
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20),
                onPressed: () => onEdit(contact, true),
                tooltip: 'Edit in modal',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () {
                  // TODO: Implement delete action
                },
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _contacts.length;

  @override
  int get selectedRowCount => 0;
}
