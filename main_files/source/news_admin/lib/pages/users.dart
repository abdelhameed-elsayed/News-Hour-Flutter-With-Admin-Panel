import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_admin/models/user.dart';
import 'package:news_admin/utils/empty.dart';
import 'package:news_admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../blocs/admin_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {


  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<DocumentSnapshot> _snap = [];
  List<User> _data = [];
  String collectionName = 'users';
  bool? _hasData;

  

  @override
  void initState() {
    controller = new ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  Future<Null> _getData() async {
    QuerySnapshot? data;
    if (_lastVisible == null)
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();
    else
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .startAfter([_lastVisible!['timestamp']])
          .limit(15)
          .get();

    if (data.docs.length > 0) {
      _lastVisible = data.docs[data.docs.length - 1];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = true;
          _snap.addAll(data!.docs);
          _data = _snap.map((e) => User.fromFirestore(e)).toList();
        });
      }
    } else {
      if(_lastVisible == null){
        setState(() {
          _isLoading = false;
          _hasData = false; 
        }); 
      }else{
        setState(() {
          _isLoading = false; 
          _hasData = true; 
        });
      openToast(context, 'No more content available'); }
    }
    return null;
  }



  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoading) {
      if (controller!.position.pixels == controller!.position.maxScrollExtent) {
        setState(() => _isLoading = true);
        _getData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            Text(
              'Users',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Container(
              margin: EdgeInsets.only(top: 5, bottom: 10),
              height: 3,
              width: 50,
              decoration: BoxDecoration(
                  color: Colors.indigoAccent,
                  borderRadius: BorderRadius.circular(15)),
            ),
            Expanded(
              child: _hasData == false 
              ? emptyPage(Icons.content_paste, 'No users found!')
              
              : RefreshIndicator(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 20, bottom: 30),
                  controller: controller,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: _data.length + 1,
                  itemBuilder: (_, int index) {
                    if (index < _data.length) {
                      return _buildUserList(_data[index]);
                    }
                    return Center(
                      child: new Opacity(
                        opacity: _isLoading ? 1.0 : 0.0,
                        child: new SizedBox(
                            width: 32.0,
                            height: 32.0,
                            child: new CircularProgressIndicator()),
                      ),
                    );
                  },
                ),
                onRefresh: () async {
                  setState(() {
                      _data.clear();
                      _snap.clear();
                      _lastVisible = null;
                    });
                },
              ),
            ),
          ],
        );
  }

  Widget _buildUserList(User d) {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    final String email = ab.isAdmin ?d.userEmail.toString() : '*******@mail.com';
    final String uid = ab.isAdmin ? d.uid.toString() : '${d.uid.toString().substring(0, 15)}**************';
    return 
    ListTile(
      leading : CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(d.imageUrl!),
      ),
      title: SelectableText(
        d.userName!,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: SelectableText('${email} \nUID: ${uid}'),
      isThreeLine: true,
      trailing: InkWell(
          child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          radius: 18,
          child: Icon(Icons.copy, size: 18,),
        ),
        onTap: (){
          Clipboard.setData(ClipboardData(text: uid));
          openToast(context, "Copied UID to clipboard");
        },
      ),
    );
  }
}