import 'package:appwrite/appwrite.dart';

const String appwriteEndpoint = 'https://nyc.cloud.appwrite.io/v1';
const String appwriteProjectId = '6a46128600370db2e820';
const String appwriteDatabaseId = 'main';
const String appwriteCollectionId = 'kato_user_info';

final Client client = Client()
  ..setProject(appwriteProjectId)
  ..setEndpoint(appwriteEndpoint);

final Databases databases = Databases(client);

