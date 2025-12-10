//
//  CountryCode.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation

struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let country: String
    let code: String
    let dialCode: String
    let flag: String
    
    var displayName: String {
        "\(flag) \(country)"
    }
    
    var fullDisplay: String {
        "\(flag) \(country) (\(dialCode))"
    }
}

class CountryCodeData {
    static let shared = CountryCodeData()
    
    private init() {}
    
    // Comprehensive list of countries with their dial codes
    let allCountryCodes: [CountryCode] = [
        CountryCode(country: "Afghanistan", code: "AF", dialCode: "+93", flag: "🇦🇫"),
        CountryCode(country: "Albania", code: "AL", dialCode: "+355", flag: "🇦🇱"),
        CountryCode(country: "Algeria", code: "DZ", dialCode: "+213", flag: "🇩🇿"),
        CountryCode(country: "American Samoa", code: "AS", dialCode: "+1684", flag: "🇦🇸"),
        CountryCode(country: "Andorra", code: "AD", dialCode: "+376", flag: "🇦🇩"),
        CountryCode(country: "Angola", code: "AO", dialCode: "+244", flag: "🇦🇴"),
        CountryCode(country: "Anguilla", code: "AI", dialCode: "+1264", flag: "🇦🇮"),
        CountryCode(country: "Antarctica", code: "AQ", dialCode: "+672", flag: "🇦🇶"),
        CountryCode(country: "Antigua and Barbuda", code: "AG", dialCode: "+1268", flag: "🇦🇬"),
        CountryCode(country: "Argentina", code: "AR", dialCode: "+54", flag: "🇦🇷"),
        CountryCode(country: "Armenia", code: "AM", dialCode: "+374", flag: "🇦🇲"),
        CountryCode(country: "Aruba", code: "AW", dialCode: "+297", flag: "🇦🇼"),
        CountryCode(country: "Australia", code: "AU", dialCode: "+61", flag: "🇦🇺"),
        CountryCode(country: "Austria", code: "AT", dialCode: "+43", flag: "🇦🇹"),
        CountryCode(country: "Azerbaijan", code: "AZ", dialCode: "+994", flag: "🇦🇿"),
        CountryCode(country: "Bahamas", code: "BS", dialCode: "+1242", flag: "🇧🇸"),
        CountryCode(country: "Bahrain", code: "BH", dialCode: "+973", flag: "🇧🇭"),
        CountryCode(country: "Bangladesh", code: "BD", dialCode: "+880", flag: "🇧🇩"),
        CountryCode(country: "Barbados", code: "BB", dialCode: "+1246", flag: "🇧🇧"),
        CountryCode(country: "Belarus", code: "BY", dialCode: "+375", flag: "🇧🇾"),
        CountryCode(country: "Belgium", code: "BE", dialCode: "+32", flag: "🇧🇪"),
        CountryCode(country: "Belize", code: "BZ", dialCode: "+501", flag: "🇧🇿"),
        CountryCode(country: "Benin", code: "BJ", dialCode: "+229", flag: "🇧🇯"),
        CountryCode(country: "Bermuda", code: "BM", dialCode: "+1441", flag: "🇧🇲"),
        CountryCode(country: "Bhutan", code: "BT", dialCode: "+975", flag: "🇧🇹"),
        CountryCode(country: "Bolivia", code: "BO", dialCode: "+591", flag: "🇧🇴"),
        CountryCode(country: "Bosnia and Herzegovina", code: "BA", dialCode: "+387", flag: "🇧🇦"),
        CountryCode(country: "Botswana", code: "BW", dialCode: "+267", flag: "🇧🇼"),
        CountryCode(country: "Brazil", code: "BR", dialCode: "+55", flag: "🇧🇷"),
        CountryCode(country: "British Indian Ocean Territory", code: "IO", dialCode: "+246", flag: "🇮🇴"),
        CountryCode(country: "British Virgin Islands", code: "VG", dialCode: "+1284", flag: "🇻🇬"),
        CountryCode(country: "Brunei", code: "BN", dialCode: "+673", flag: "🇧🇳"),
        CountryCode(country: "Bulgaria", code: "BG", dialCode: "+359", flag: "🇧🇬"),
        CountryCode(country: "Burkina Faso", code: "BF", dialCode: "+226", flag: "🇧🇫"),
        CountryCode(country: "Burundi", code: "BI", dialCode: "+257", flag: "🇧🇮"),
        CountryCode(country: "Cambodia", code: "KH", dialCode: "+855", flag: "🇰🇭"),
        CountryCode(country: "Cameroon", code: "CM", dialCode: "+237", flag: "🇨🇲"),
        CountryCode(country: "Canada", code: "CA", dialCode: "+1", flag: "🇨🇦"),
        CountryCode(country: "Cape Verde", code: "CV", dialCode: "+238", flag: "🇨🇻"),
        CountryCode(country: "Cayman Islands", code: "KY", dialCode: "+1345", flag: "🇰🇾"),
        CountryCode(country: "Central African Republic", code: "CF", dialCode: "+236", flag: "🇨🇫"),
        CountryCode(country: "Chad", code: "TD", dialCode: "+235", flag: "🇹🇩"),
        CountryCode(country: "Chile", code: "CL", dialCode: "+56", flag: "🇨🇱"),
        CountryCode(country: "China", code: "CN", dialCode: "+86", flag: "🇨🇳"),
        CountryCode(country: "Christmas Island", code: "CX", dialCode: "+61", flag: "🇨🇽"),
        CountryCode(country: "Cocos Islands", code: "CC", dialCode: "+61", flag: "🇨🇨"),
        CountryCode(country: "Colombia", code: "CO", dialCode: "+57", flag: "🇨🇴"),
        CountryCode(country: "Comoros", code: "KM", dialCode: "+269", flag: "🇰🇲"),
        CountryCode(country: "Cook Islands", code: "CK", dialCode: "+682", flag: "🇨🇰"),
        CountryCode(country: "Costa Rica", code: "CR", dialCode: "+506", flag: "🇨🇷"),
        CountryCode(country: "Croatia", code: "HR", dialCode: "+385", flag: "🇭🇷"),
        CountryCode(country: "Cuba", code: "CU", dialCode: "+53", flag: "🇨🇺"),
        CountryCode(country: "Curacao", code: "CW", dialCode: "+599", flag: "🇨🇼"),
        CountryCode(country: "Cyprus", code: "CY", dialCode: "+357", flag: "🇨🇾"),
        CountryCode(country: "Czech Republic", code: "CZ", dialCode: "+420", flag: "🇨🇿"),
        CountryCode(country: "Democratic Republic of the Congo", code: "CD", dialCode: "+243", flag: "🇨🇩"),
        CountryCode(country: "Denmark", code: "DK", dialCode: "+45", flag: "🇩🇰"),
        CountryCode(country: "Djibouti", code: "DJ", dialCode: "+253", flag: "🇩🇯"),
        CountryCode(country: "Dominica", code: "DM", dialCode: "+1767", flag: "🇩🇲"),
        CountryCode(country: "Dominican Republic", code: "DO", dialCode: "+1809", flag: "🇩🇴"),
        CountryCode(country: "East Timor", code: "TL", dialCode: "+670", flag: "🇹🇱"),
        CountryCode(country: "Ecuador", code: "EC", dialCode: "+593", flag: "🇪🇨"),
        CountryCode(country: "Egypt", code: "EG", dialCode: "+20", flag: "🇪🇬"),
        CountryCode(country: "El Salvador", code: "SV", dialCode: "+503", flag: "🇸🇻"),
        CountryCode(country: "Equatorial Guinea", code: "GQ", dialCode: "+240", flag: "🇬🇶"),
        CountryCode(country: "Eritrea", code: "ER", dialCode: "+291", flag: "🇪🇷"),
        CountryCode(country: "Estonia", code: "EE", dialCode: "+372", flag: "🇪🇪"),
        CountryCode(country: "Ethiopia", code: "ET", dialCode: "+251", flag: "🇪🇹"),
        CountryCode(country: "Falkland Islands", code: "FK", dialCode: "+500", flag: "🇫🇰"),
        CountryCode(country: "Faroe Islands", code: "FO", dialCode: "+298", flag: "🇫🇴"),
        CountryCode(country: "Fiji", code: "FJ", dialCode: "+679", flag: "🇫🇯"),
        CountryCode(country: "Finland", code: "FI", dialCode: "+358", flag: "🇫🇮"),
        CountryCode(country: "France", code: "FR", dialCode: "+33", flag: "🇫🇷"),
        CountryCode(country: "French Polynesia", code: "PF", dialCode: "+689", flag: "🇵🇫"),
        CountryCode(country: "Gabon", code: "GA", dialCode: "+241", flag: "🇬🇦"),
        CountryCode(country: "Gambia", code: "GM", dialCode: "+220", flag: "🇬🇲"),
        CountryCode(country: "Georgia", code: "GE", dialCode: "+995", flag: "🇬🇪"),
        CountryCode(country: "Germany", code: "DE", dialCode: "+49", flag: "🇩🇪"),
        CountryCode(country: "Ghana", code: "GH", dialCode: "+233", flag: "🇬🇭"),
        CountryCode(country: "Gibraltar", code: "GI", dialCode: "+350", flag: "🇬🇮"),
        CountryCode(country: "Greece", code: "GR", dialCode: "+30", flag: "🇬🇷"),
        CountryCode(country: "Greenland", code: "GL", dialCode: "+299", flag: "🇬🇱"),
        CountryCode(country: "Grenada", code: "GD", dialCode: "+1473", flag: "🇬🇩"),
        CountryCode(country: "Guam", code: "GU", dialCode: "+1671", flag: "🇬🇺"),
        CountryCode(country: "Guatemala", code: "GT", dialCode: "+502", flag: "🇬🇹"),
        CountryCode(country: "Guernsey", code: "GG", dialCode: "+441481", flag: "🇬🇬"),
        CountryCode(country: "Guinea", code: "GN", dialCode: "+224", flag: "🇬🇳"),
        CountryCode(country: "Guinea-Bissau", code: "GW", dialCode: "+245", flag: "🇬🇼"),
        CountryCode(country: "Guyana", code: "GY", dialCode: "+592", flag: "🇬🇾"),
        CountryCode(country: "Haiti", code: "HT", dialCode: "+509", flag: "🇭🇹"),
        CountryCode(country: "Honduras", code: "HN", dialCode: "+504", flag: "🇭🇳"),
        CountryCode(country: "Hong Kong", code: "HK", dialCode: "+852", flag: "🇭🇰"),
        CountryCode(country: "Hungary", code: "HU", dialCode: "+36", flag: "🇭🇺"),
        CountryCode(country: "Iceland", code: "IS", dialCode: "+354", flag: "🇮🇸"),
        CountryCode(country: "India", code: "IN", dialCode: "+91", flag: "🇮🇳"),
        CountryCode(country: "Indonesia", code: "ID", dialCode: "+62", flag: "🇮🇩"),
        CountryCode(country: "Iran", code: "IR", dialCode: "+98", flag: "🇮🇷"),
        CountryCode(country: "Iraq", code: "IQ", dialCode: "+964", flag: "🇮🇶"),
        CountryCode(country: "Ireland", code: "IE", dialCode: "+353", flag: "🇮🇪"),
        CountryCode(country: "Isle of Man", code: "IM", dialCode: "+441624", flag: "🇮🇲"),
        CountryCode(country: "Israel", code: "IL", dialCode: "+972", flag: "🇮🇱"),
        CountryCode(country: "Italy", code: "IT", dialCode: "+39", flag: "🇮🇹"),
        CountryCode(country: "Ivory Coast", code: "CI", dialCode: "+225", flag: "🇨🇮"),
        CountryCode(country: "Jamaica", code: "JM", dialCode: "+1876", flag: "🇯🇲"),
        CountryCode(country: "Japan", code: "JP", dialCode: "+81", flag: "🇯🇵"),
        CountryCode(country: "Jersey", code: "JE", dialCode: "+441534", flag: "🇯🇪"),
        CountryCode(country: "Jordan", code: "JO", dialCode: "+962", flag: "🇯🇴"),
        CountryCode(country: "Kazakhstan", code: "KZ", dialCode: "+7", flag: "🇰🇿"),
        CountryCode(country: "Kenya", code: "KE", dialCode: "+254", flag: "🇰🇪"),
        CountryCode(country: "Kiribati", code: "KI", dialCode: "+686", flag: "🇰🇮"),
        CountryCode(country: "Kosovo", code: "XK", dialCode: "+383", flag: "🇽🇰"),
        CountryCode(country: "Kuwait", code: "KW", dialCode: "+965", flag: "🇰🇼"),
        CountryCode(country: "Kyrgyzstan", code: "KG", dialCode: "+996", flag: "🇰🇬"),
        CountryCode(country: "Laos", code: "LA", dialCode: "+856", flag: "🇱🇦"),
        CountryCode(country: "Latvia", code: "LV", dialCode: "+371", flag: "🇱🇻"),
        CountryCode(country: "Lebanon", code: "LB", dialCode: "+961", flag: "🇱🇧"),
        CountryCode(country: "Lesotho", code: "LS", dialCode: "+266", flag: "🇱🇸"),
        CountryCode(country: "Liberia", code: "LR", dialCode: "+231", flag: "🇱🇷"),
        CountryCode(country: "Libya", code: "LY", dialCode: "+218", flag: "🇱🇾"),
        CountryCode(country: "Liechtenstein", code: "LI", dialCode: "+423", flag: "🇱🇮"),
        CountryCode(country: "Lithuania", code: "LT", dialCode: "+370", flag: "🇱🇹"),
        CountryCode(country: "Luxembourg", code: "LU", dialCode: "+352", flag: "🇱🇺"),
        CountryCode(country: "Macau", code: "MO", dialCode: "+853", flag: "🇲🇴"),
        CountryCode(country: "North Macedonia", code: "MK", dialCode: "+389", flag: "🇲🇰"),
        CountryCode(country: "Madagascar", code: "MG", dialCode: "+261", flag: "🇲🇬"),
        CountryCode(country: "Malawi", code: "MW", dialCode: "+265", flag: "🇲🇼"),
        CountryCode(country: "Malaysia", code: "MY", dialCode: "+60", flag: "🇲🇾"),
        CountryCode(country: "Maldives", code: "MV", dialCode: "+960", flag: "🇲🇻"),
        CountryCode(country: "Mali", code: "ML", dialCode: "+223", flag: "🇲🇱"),
        CountryCode(country: "Malta", code: "MT", dialCode: "+356", flag: "🇲🇹"),
        CountryCode(country: "Marshall Islands", code: "MH", dialCode: "+692", flag: "🇲🇭"),
        CountryCode(country: "Mauritania", code: "MR", dialCode: "+222", flag: "🇲🇷"),
        CountryCode(country: "Mauritius", code: "MU", dialCode: "+230", flag: "🇲🇺"),
        CountryCode(country: "Mayotte", code: "YT", dialCode: "+262", flag: "🇾🇹"),
        CountryCode(country: "Mexico", code: "MX", dialCode: "+52", flag: "🇲🇽"),
        CountryCode(country: "Micronesia", code: "FM", dialCode: "+691", flag: "🇫🇲"),
        CountryCode(country: "Moldova", code: "MD", dialCode: "+373", flag: "🇲🇩"),
        CountryCode(country: "Monaco", code: "MC", dialCode: "+377", flag: "🇲🇨"),
        CountryCode(country: "Mongolia", code: "MN", dialCode: "+976", flag: "🇲🇳"),
        CountryCode(country: "Montenegro", code: "ME", dialCode: "+382", flag: "🇲🇪"),
        CountryCode(country: "Montserrat", code: "MS", dialCode: "+1664", flag: "🇲🇸"),
        CountryCode(country: "Morocco", code: "MA", dialCode: "+212", flag: "🇲🇦"),
        CountryCode(country: "Mozambique", code: "MZ", dialCode: "+258", flag: "🇲🇿"),
        CountryCode(country: "Myanmar", code: "MM", dialCode: "+95", flag: "🇲🇲"),
        CountryCode(country: "Namibia", code: "NA", dialCode: "+264", flag: "🇳🇦"),
        CountryCode(country: "Nauru", code: "NR", dialCode: "+674", flag: "🇳🇷"),
        CountryCode(country: "Nepal", code: "NP", dialCode: "+977", flag: "🇳🇵"),
        CountryCode(country: "Netherlands", code: "NL", dialCode: "+31", flag: "🇳🇱"),
        CountryCode(country: "New Caledonia", code: "NC", dialCode: "+687", flag: "🇳🇨"),
        CountryCode(country: "New Zealand", code: "NZ", dialCode: "+64", flag: "🇳🇿"),
        CountryCode(country: "Nicaragua", code: "NI", dialCode: "+505", flag: "🇳🇮"),
        CountryCode(country: "Niger", code: "NE", dialCode: "+227", flag: "🇳🇪"),
        CountryCode(country: "Nigeria", code: "NG", dialCode: "+234", flag: "🇳🇬"),
        CountryCode(country: "Niue", code: "NU", dialCode: "+683", flag: "🇳🇺"),
        CountryCode(country: "North Korea", code: "KP", dialCode: "+850", flag: "🇰🇵"),
        CountryCode(country: "Northern Mariana Islands", code: "MP", dialCode: "+1670", flag: "🇲🇵"),
        CountryCode(country: "Norway", code: "NO", dialCode: "+47", flag: "🇳🇴"),
        CountryCode(country: "Oman", code: "OM", dialCode: "+968", flag: "🇴🇲"),
        CountryCode(country: "Pakistan", code: "PK", dialCode: "+92", flag: "🇵🇰"),
        CountryCode(country: "Palau", code: "PW", dialCode: "+680", flag: "🇵🇼"),
        CountryCode(country: "Palestine", code: "PS", dialCode: "+970", flag: "🇵🇸"),
        CountryCode(country: "Panama", code: "PA", dialCode: "+507", flag: "🇵🇦"),
        CountryCode(country: "Papua New Guinea", code: "PG", dialCode: "+675", flag: "🇵🇬"),
        CountryCode(country: "Paraguay", code: "PY", dialCode: "+595", flag: "🇵🇾"),
        CountryCode(country: "Peru", code: "PE", dialCode: "+51", flag: "🇵🇪"),
        CountryCode(country: "Philippines", code: "PH", dialCode: "+63", flag: "🇵🇭"),
        CountryCode(country: "Pitcairn", code: "PN", dialCode: "+64", flag: "🇵🇳"),
        CountryCode(country: "Poland", code: "PL", dialCode: "+48", flag: "🇵🇱"),
        CountryCode(country: "Portugal", code: "PT", dialCode: "+351", flag: "🇵🇹"),
        CountryCode(country: "Puerto Rico", code: "PR", dialCode: "+1787", flag: "🇵🇷"),
        CountryCode(country: "Qatar", code: "QA", dialCode: "+974", flag: "🇶🇦"),
        CountryCode(country: "Republic of the Congo", code: "CG", dialCode: "+242", flag: "🇨🇬"),
        CountryCode(country: "Reunion", code: "RE", dialCode: "+262", flag: "🇷🇪"),
        CountryCode(country: "Romania", code: "RO", dialCode: "+40", flag: "🇷🇴"),
        CountryCode(country: "Russia", code: "RU", dialCode: "+7", flag: "🇷🇺"),
        CountryCode(country: "Rwanda", code: "RW", dialCode: "+250", flag: "🇷🇼"),
        CountryCode(country: "Saint Barthelemy", code: "BL", dialCode: "+590", flag: "🇧🇱"),
        CountryCode(country: "Saint Helena", code: "SH", dialCode: "+290", flag: "🇸🇭"),
        CountryCode(country: "Saint Kitts and Nevis", code: "KN", dialCode: "+1869", flag: "🇰🇳"),
        CountryCode(country: "Saint Lucia", code: "LC", dialCode: "+1758", flag: "🇱🇨"),
        CountryCode(country: "Saint Martin", code: "MF", dialCode: "+590", flag: "🇲🇫"),
        CountryCode(country: "Saint Pierre and Miquelon", code: "PM", dialCode: "+508", flag: "🇵🇲"),
        CountryCode(country: "Saint Vincent and the Grenadines", code: "VC", dialCode: "+1784", flag: "🇻🇨"),
        CountryCode(country: "Samoa", code: "WS", dialCode: "+685", flag: "🇼🇸"),
        CountryCode(country: "San Marino", code: "SM", dialCode: "+378", flag: "🇸🇲"),
        CountryCode(country: "Sao Tome and Principe", code: "ST", dialCode: "+239", flag: "🇸🇹"),
        CountryCode(country: "Saudi Arabia", code: "SA", dialCode: "+966", flag: "🇸🇦"),
        CountryCode(country: "Senegal", code: "SN", dialCode: "+221", flag: "🇸🇳"),
        CountryCode(country: "Serbia", code: "RS", dialCode: "+381", flag: "🇷🇸"),
        CountryCode(country: "Seychelles", code: "SC", dialCode: "+248", flag: "🇸🇨"),
        CountryCode(country: "Sierra Leone", code: "SL", dialCode: "+232", flag: "🇸🇱"),
        CountryCode(country: "Singapore", code: "SG", dialCode: "+65", flag: "🇸🇬"),
        CountryCode(country: "Sint Maarten", code: "SX", dialCode: "+1721", flag: "🇸🇽"),
        CountryCode(country: "Slovakia", code: "SK", dialCode: "+421", flag: "🇸🇰"),
        CountryCode(country: "Slovenia", code: "SI", dialCode: "+386", flag: "🇸🇮"),
        CountryCode(country: "Solomon Islands", code: "SB", dialCode: "+677", flag: "🇸🇧"),
        CountryCode(country: "Somalia", code: "SO", dialCode: "+252", flag: "🇸🇴"),
        CountryCode(country: "South Africa", code: "ZA", dialCode: "+27", flag: "🇿🇦"),
        CountryCode(country: "South Korea", code: "KR", dialCode: "+82", flag: "🇰🇷"),
        CountryCode(country: "South Sudan", code: "SS", dialCode: "+211", flag: "🇸🇸"),
        CountryCode(country: "Spain", code: "ES", dialCode: "+34", flag: "🇪🇸"),
        CountryCode(country: "Sri Lanka", code: "LK", dialCode: "+94", flag: "🇱🇰"),
        CountryCode(country: "Sudan", code: "SD", dialCode: "+249", flag: "🇸🇩"),
        CountryCode(country: "Suriname", code: "SR", dialCode: "+597", flag: "🇸🇷"),
        CountryCode(country: "Svalbard and Jan Mayen", code: "SJ", dialCode: "+47", flag: "🇸🇯"),
        CountryCode(country: "Eswatini", code: "SZ", dialCode: "+268", flag: "🇸🇿"),
        CountryCode(country: "Sweden", code: "SE", dialCode: "+46", flag: "🇸🇪"),
        CountryCode(country: "Switzerland", code: "CH", dialCode: "+41", flag: "🇨🇭"),
        CountryCode(country: "Syria", code: "SY", dialCode: "+963", flag: "🇸🇾"),
        CountryCode(country: "Taiwan", code: "TW", dialCode: "+886", flag: "🇹🇼"),
        CountryCode(country: "Tajikistan", code: "TJ", dialCode: "+992", flag: "🇹🇯"),
        CountryCode(country: "Tanzania", code: "TZ", dialCode: "+255", flag: "🇹🇿"),
        CountryCode(country: "Thailand", code: "TH", dialCode: "+66", flag: "🇹🇭"),
        CountryCode(country: "Togo", code: "TG", dialCode: "+228", flag: "🇹🇬"),
        CountryCode(country: "Tokelau", code: "TK", dialCode: "+690", flag: "🇹🇰"),
        CountryCode(country: "Tonga", code: "TO", dialCode: "+676", flag: "🇹🇴"),
        CountryCode(country: "Trinidad and Tobago", code: "TT", dialCode: "+1868", flag: "🇹🇹"),
        CountryCode(country: "Tunisia", code: "TN", dialCode: "+216", flag: "🇹🇳"),
        CountryCode(country: "Turkey", code: "TR", dialCode: "+90", flag: "🇹🇷"),
        CountryCode(country: "Turkmenistan", code: "TM", dialCode: "+993", flag: "🇹🇲"),
        CountryCode(country: "Turks and Caicos Islands", code: "TC", dialCode: "+1649", flag: "🇹🇨"),
        CountryCode(country: "Tuvalu", code: "TV", dialCode: "+688", flag: "🇹🇻"),
        CountryCode(country: "U.S. Virgin Islands", code: "VI", dialCode: "+1340", flag: "🇻🇮"),
        CountryCode(country: "Uganda", code: "UG", dialCode: "+256", flag: "🇺🇬"),
        CountryCode(country: "Ukraine", code: "UA", dialCode: "+380", flag: "🇺🇦"),
        CountryCode(country: "United Arab Emirates", code: "AE", dialCode: "+971", flag: "🇦🇪"),
        CountryCode(country: "United Kingdom", code: "GB", dialCode: "+44", flag: "🇬🇧"),
        CountryCode(country: "United States", code: "US", dialCode: "+1", flag: "🇺🇸"),
        CountryCode(country: "Uruguay", code: "UY", dialCode: "+598", flag: "🇺🇾"),
        CountryCode(country: "Uzbekistan", code: "UZ", dialCode: "+998", flag: "🇺🇿"),
        CountryCode(country: "Vanuatu", code: "VU", dialCode: "+678", flag: "🇻🇺"),
        CountryCode(country: "Venezuela", code: "VE", dialCode: "+58", flag: "🇻🇪"),
        CountryCode(country: "Vietnam", code: "VN", dialCode: "+84", flag: "🇻🇳"),
        CountryCode(country: "Wallis and Futuna", code: "WF", dialCode: "+681", flag: "🇼🇫"),
        CountryCode(country: "Western Sahara", code: "EH", dialCode: "+212", flag: "🇪🇭"),
        CountryCode(country: "Yemen", code: "YE", dialCode: "+967", flag: "🇾🇪"),
        CountryCode(country: "Zambia", code: "ZM", dialCode: "+260", flag: "🇿🇲"),
        CountryCode(country: "Zimbabwe", code: "ZW", dialCode: "+263", flag: "🇿🇼"),
    ]
    
    /// Get country code based on device locale
    func getDefaultCountryCode() -> CountryCode {
        let regionCode = Locale.current.region?.identifier ?? "CH"
        print("🌍 Device region code: \(regionCode)")
        
        if let countryCode = allCountryCodes.first(where: { $0.code == regionCode }) {
            print("✅ Found matching country: \(countryCode.country) (\(countryCode.dialCode))")
            return countryCode
        }
        
        // Default to Switzerland if not found
        print("⚠️ Region not found, defaulting to Switzerland")
        return allCountryCodes.first(where: { $0.code == "CH" })!
    }
    
    /// Search countries by name or dial code
    func search(_ query: String) -> [CountryCode] {
        guard !query.isEmpty else { return allCountryCodes }
        
        let lowercaseQuery = query.lowercased()
        return allCountryCodes.filter { country in
            country.country.lowercased().contains(lowercaseQuery) ||
            country.dialCode.contains(query) ||
            country.code.lowercased().contains(lowercaseQuery)
        }
    }
}
