import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

class ListGroupsView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ListGroupsViewState();
}

class _ListGroupsViewState extends State<ListGroupsView> {
  final dio = Dio();
  String _searchQuery = '';
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _filterGroups() async {
    final box = Hive.box('myBox'); // получаем доступ к боксу с именем 'myBox'
    if (box.containsKey('groups')) {
      // проверяем наличие сохраненных данных в боксе
      final groups =
          List.from(box.get('groups')); // получаем сохраненные данные из бокса
      if (_searchQuery.isNotEmpty) {
        return groups
            .where((group) => group['name']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      } else {
        return groups;
      }
    } else {
      final response = await dio.get('http://192.168.0.111:3001/api/groups');
      if (response.statusCode == 200) {
        final groups = List.from(response.data);
        box.put('groups', groups); // сохраняем полученные данные в боксе
        if (_searchQuery.isNotEmpty) {
          return groups
              .where((group) => group['name']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();
        } else {
          return groups;
        }
      } else {
        throw Exception('Failed to load groups');
      }
    }
  }

  Widget buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        border: InputBorder.none,
        icon: Icon(Icons.search),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      focusNode: _focusNode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Title'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildSearchField(),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _filterGroups(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollUpdateNotification) {
                          _focusNode.unfocus(); // снимаем фокус с поля поиска
                        }
                        return true;
                      },
                      child: ListView.builder(
                        itemCount: snapshot.data?.length,
                        itemBuilder: (context, index) {
                          return CustomCard(
                            title: snapshot.data![index]['name'],
                            subtitle:
                                'Start time: ${snapshot.data![index]['startTime']}, End time: ${snapshot.data![index]['endTime']}',
                          );
                        },
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final String subtitle;

  CustomCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor, // задаем цвет карточки
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
