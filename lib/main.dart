import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_integration/payment_page.dart';

Future<void> main() async {
  //Initialize Flutter Binding
  WidgetsFlutterBinding.ensureInitialized();
  //Assign publishable key to flutter_stripe
  Stripe.publishableKey = "pk_test_51OSco6FvvEIp28cvZpZBsWhiuYAyPq0R9E3d5Xrnvy598U2uonPpfplNL6pkqcM7XtVlNNrCEMWKe0cPDI3z5jhK00mqjmR8jk";
  //Load our .env file that contains our Stripe Secret key
  await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaymentPage(),
    );
  }
}

class Home extends StatelessWidget {

  Map<String,dynamic>? paymentIntent ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                await makePayment(context);
              },
              child: const Text("Make Payment"),
            ),
            TextButton(
              onPressed: () async {
                await getMethodId();
              },
              child: const Text("Get ID"),
            ),
            // TextButton(
            //   onPressed: () async {
            //     Stripe.instance.applySettings();
            //   },
            //   child: const Text("Apple pay"),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> makePayment(context) async {
    try {
      //STEP 1: Create Payment Intent
      paymentIntent = await createPaymentIntent('100', 'USD');

      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'], //Gotten from payment intent
              style: ThemeMode.light,
              // applePay:const PaymentSheetApplePay(merchantCountryCode: "US"),
              // googlePay:const PaymentSheetGooglePay(merchantCountryCode: "US"),
              merchantDisplayName: 'Ikay'))
          .then((value) {});

      //STEP 3: Display Payment sheet
      displayPaymentSheet(context);
    } catch (err) {
      throw Exception(err);
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  displayPaymentSheet(context) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100.0,
                  ),
                  SizedBox(height: 10.0),
                  Text("Payment Successful!"),
                ],
              ),
            ));

        // paymentIntent = null;
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  Future<void> getMethodId() async {
    try {
      // Create PaymentMethodParams with BillingDetails and Address
      var params = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            name: 'John Doe',
            email: 'john.doe@example.com',
            phone: '+1234567890',
            address: Address(
              city: 'San Francisco',
              country: 'US',
              line1: '123 Main St',
              line2: 'Apartment 4',
              postalCode: '94107',
              state: 'CA',
            ),
          ),
        ),
      );

      // Create the payment method
      final paymentMethod = await Stripe.instance.createPaymentMethod(params: params);

      // Check if the paymentMethod was created successfully and print the ID
      if (paymentMethod != null) {
        print('Payment Method ID: ${paymentMethod.id}');
      } else {
        print('Payment Method creation failed.');
      }
    } catch (e) {
      // Catch any exceptions and print error message
      print('Error: $e');
    }
  }

}
