import 'package:flutter/material.dart';

// Button widget with simple label
TextButton myButton(String label) {
  return TextButton(
    onPressed: () {},
    child: Text(
      label,
      style: const TextStyle(color: Colors.black, fontSize: 17),
    ),
  );
}

// Custom button widget with a container and action callback
Container myButton2(
  BuildContext context,
  String title,
  Function onTap, {
  double? width,
  double? height,
}) {
  return Container(
    width: width ?? MediaQuery.of(context).size.width * 0.5,
    height: height ?? 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () => onTap(),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return Colors.blue;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}

// Custom text field widget for email and password inputs
Widget myTextForm(
  IconData icon,
  String labelText,
  bool obscureText,
  bool isPassword,
  TextEditingController controller,
  VoidCallback? onPressed, {
  TextInputType? keyboardType,
  int? maxLength,
  String? Function(String?)? validator,
}) {
  return SizedBox(
    height: 60,
    width: 400,
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        prefixIcon: Icon(icon),
        focusColor: Colors.blueAccent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 81, 181, 243),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 38, 173, 240),
            width: 2,
          ),
        ),
        labelText: labelText,
        labelStyle: const TextStyle(fontSize: 10),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: onPressed,  // Toggling password visibility
              )
            : null,
      ),
    ),
  );
}

// Logo widget for displaying an image that can be tapped
Widget logoWidget(String fName, double height, double width) {
  return GestureDetector(
    child: Image.asset(
      fName,
      height: height,
      width: width,
    ),
    onTap: () {},  // Add any action you want when the logo is tapped
  );
}



Container myCustomContainer(
  BuildContext context,
  Widget child, {
  double? width,
  double? height,
  EdgeInsetsGeometry? margin,
  BoxDecoration? decoration,
}) {
  return Container(
    width: width ?? MediaQuery.of(context).size.width * 0.5,
    height: height ?? 50,
    margin: margin ?? const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: decoration ?? BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: child,
  );
}


Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Container myButtoncontact(
    BuildContext context,
    Icon icon,
    String title,
    Function onTap,{
     double? width,
    double? height,
    }
  ) {
  return Container(
    width: width ?? MediaQuery.of(context).size.width * 12,
    height: height ?? 6,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () => onTap(),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return Colors.blue;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}