import 'package:flutter/material.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:uuid/uuid.dart';

class CreateServerScreen extends StatefulWidget {
  @override
  _CreateServerScreenState createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool get _canSave => true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Create Server'),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.save),
                onPressed: _canSave ? () => _saveAndPop(context) : null,
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: 'Server Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'This Field is Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _userCtrl,
                decoration: InputDecoration(
                  labelText: 'User',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'This Field is Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'This Field is Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'This Field is Required';

                  final uri = Uri.tryParse(value);
                  if (uri == null) return 'Please enter a valid URL';

                  if (!['http', 'https'].contains(uri.scheme))
                    return 'Please enter a http or https URL';

                  return null;
                },
              ),
            ],
          ),
        ),
      );

  void _saveAndPop(BuildContext context) {
    if (_formKey.currentState.validate()) {
      final server = SubsonicContext(
        serverId: Uuid().v4(),
        name: _nameCtrl.text,
        user: _userCtrl.text,
        pass: _passCtrl.text,
        endpoint: Uri.parse(_urlCtrl.text),
      );
      Navigator.of(context).pop(server);
    }
  }
}
