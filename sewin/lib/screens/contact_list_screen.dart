import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../services/auth_service.dart';
import 'contact_form_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import '../widgets/app_drawer.dart';

class ContactListScreen extends StatefulWidget {
  final int version;
  final String title;

  const ContactListScreen({
    super.key,
    this.version = 0,
    this.title = 'Contact 000',
  });

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  late List<Contact> _allContacts;
  late List<Contact> _filteredContacts;
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

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

  @override
  void initState() {
    super.initState();
    _allContacts = ContactService.getMockContacts();
    _filteredContacts = List.from(_allContacts);
    print('Contacts loaded: ${_filteredContacts.length}');
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredContacts = _allContacts.where((contact) {
        return contact.fullName.toLowerCase().contains(_searchQuery) ||
            contact.email.toLowerCase().contains(_searchQuery) ||
            contact.businessName.toLowerCase().contains(_searchQuery) ||
            contact.phoneNumber.toLowerCase().contains(_searchQuery) ||
            contact.idContact.toLowerCase().contains(_searchQuery);
      }).toList();
      // Update filtered contacts
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'change_password') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'change_password',
                child: Text('Change Password'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final contact = await Navigator.push<Contact>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactFormScreen(contact: null),
                ),
              );
              if (contact != null) {
                setState(() {
                  _allContacts.add(contact);
                  _filterContacts(_searchController.text);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Contact'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final contact = await showDialog<Contact>(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height * 0.8,
                      padding: const EdgeInsets.all(8.0),
                      child: ContactFormScreen(contact: null),
                    ),
                  );
                },
              );
              if (contact != null) {
                setState(() {
                  _allContacts.add(contact);
                  _filterContacts(_searchController.text);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Add Modal'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[800]),
                    header: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterContacts,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _filterContacts('');
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    showFirstLastButtons: true,
                    rowsPerPage: _rowsPerPage,
                    onRowsPerPageChanged: (value) {
                      setState(() {
                        _rowsPerPage = value!;
                      });
                    },
                    availableRowsPerPage: const [10, 25, 50],
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ID',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 0)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'ID',
                        onSort: (columnIndex, ascending) {
                          _sort<String>((contact) => contact.idContact,
                              columnIndex, ascending);
                        },
                        // sortAscending: _sortAscending,
                      ),
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Full Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 1)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Full Name',
                        onSort: (columnIndex, ascending) {
                          _sort<String>((contact) => contact.fullName,
                              columnIndex, ascending);
                        },
                        //  sortAscending: _sortAscending,
                      ),
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Phone',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 2)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Phone Number',
                        onSort: (columnIndex, ascending) {
                          _sort<String>((contact) => contact.phoneNumber,
                              columnIndex, ascending);
                        },
                        //   sortAscending: _sortAscending,
                      ),
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Email',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 3)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Email',
                        onSort: (columnIndex, ascending) {
                          _sort<String>((contact) => contact.email, columnIndex,
                              ascending);
                        },
                        // sortAscending: _sortAscending,
                      ),
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Business',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 4)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Business Name',
                        onSort: (columnIndex, ascending) {
                          _sort<String>((contact) => contact.businessName,
                              columnIndex, ascending);
                        },
                        //   sortAscending: _sortAscending,
                      ),
                      DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            if (_sortColumnIndex == 5)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_circle_down
                                      : Icons.arrow_circle_up,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Created At',
                        onSort: (columnIndex, ascending) {
                          _sort<DateTime>((contact) => contact.createdAt,
                              columnIndex, ascending);
                        },
                        // sortAscending: _sortAscending,
                      ),
                      const DataColumn(
                        label: Text('Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        tooltip: 'Actions',
                        //   sortable: false
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  height:
                                      MediaQuery.of(context).size.height * 0.8,
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
                              _allContacts[index] = updatedContact as Contact;
                              _filterContacts(_searchController.text);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
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
                onPressed: () {
                  onEdit(contact, true);
                },
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

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
