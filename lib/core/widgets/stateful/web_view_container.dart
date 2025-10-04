part of '../widgets.dart';

class WebViewContainer extends StatefulWidget {
  final int id;
  const WebViewContainer({super.key, required this.url, required this.id});

  final String url;

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late final WebViewController controller;
  bool isLoading = true;
  bool isConnected = true;
  bool isErorr = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) async {
          logger("New Request is ${request.url}");
          if (request.url.contains('https://nnursing.net/nursing-app/api/')) {
            _handleCallback(Uri.parse(request.url));
            return NavigationDecision.navigate; // Prevent further navigation
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
            isErorr = false;
          });
        },
        onPageFinished: (url) {
          setState(() {
            isLoading = false;
            isErorr = false;
          });
        },
        onWebResourceError: (error) {
          setState(() {
            isLoading = false;
            isErorr = true;
          });
          debugPrint("Failed to load the page: ${error.description}");
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () =>  context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (isConnected && !isErorr) WebViewWidget(controller: controller),
            if (!isConnected || isErorr)
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(width: 1, style: BorderStyle.solid),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FlexibleImage(
                          source:
                          'assets/internet_disconected-removebg-preview.png',
                        ),
                        Text(
                          'No Internet Connection',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (isLoading)
              Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: context.colorScheme.secondary,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _handleCallback(Uri uri) {
    loggerWarn(uri.toString());
    final status = uri.queryParameters['success'];

    if (status == 'true') {

      // !UserData.isPatient? context.goWithNoReturn(const PatientScreen()): context.goWithNoReturn(const NurserScreen());
    } else {

    }
  }
}