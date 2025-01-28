import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  CardFieldInputDetails? _card;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stripe Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CardField widget for collecting card details
            CardField(
              onCardChanged: (card) {
                setState(() {
                  _card = card;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _card?.complete == true ? _makePaymentWithCard : null,
              child: Text('Make Payment with Card'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _makePaymentWithApplePay,
              child: Text('Make Payment with Apple Pay'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _makePaymentWithGooglePay,
              child: Text('Make Payment with Google Pay'),
            ),
          ],
        ),
      ),
    );
  }

  // This method is called when the user clicks 'Make Payment with Card' button
  Future<void> _makePaymentWithCard() async {
    try {
      // Define payment method data for card
      var paymentMethodParams = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            name: 'John Doe',
            email: 'john.doe@example.com',
            phone: '+1234567890',
          ),
        ),
      );

      // Create the payment method
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: paymentMethodParams,
      );

      print('Payment Method ID (Card): ${paymentMethod.id}');
      // Send this ID to your backend to complete the payment
    } catch (e) {
      print('Error creating payment method: $e');
    }
  }

  // This method is called when the user clicks 'Make Payment with Apple Pay' button
  Future<void> _makePaymentWithApplePay() async {
    try {
      // Define the payment details for Apple Pay
      final paymentIntent = await createPaymentIntent('100', 'USD');

      // Configure PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'], // Get this from your backend
          style: ThemeMode.light,
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'US'),
          merchantDisplayName: 'Test Merchant',  // Set your merchant name
        ),
      );

      // Show the payment sheet
      await Stripe.instance.presentPaymentSheet();
      print('Payment successful (Apple Pay)');
    } catch (e) {
      print('Error with Apple Pay payment: $e');
    }
  }

  // This method is called when the user clicks 'Make Payment with Google Pay' button
  Future<void> _makePaymentWithGooglePay() async {
    try {
      // Define the payment details for Google Pay
      final paymentIntent = await createPaymentIntent('100', 'USD');

      // Configure PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'], // Get this from your backend
          googlePay: const PaymentSheetGooglePay(merchantCountryCode: 'US'),
          merchantDisplayName: 'Test Merchant',  // Set your merchant name
        ),
      );

      // Show the payment sheet
      await Stripe.instance.presentPaymentSheet();
      print('Payment successful (Google Pay)');
    } catch (e) {
      print('Error with Google Pay payment: $e');
    }
  }

  // Create a payment intent on your backend
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
}
