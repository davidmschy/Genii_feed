// Defines the data models for the trust-based payment system.

class TrustAccount {
  final String id;
  final String propertyId; // Links to a property in the system
  final String name; // e.g., "Main Operating Account for Property X"
  final List<TrustStakeholder> stakeholders;
  final List<CashFlowRule> rules;

  TrustAccount({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.stakeholders,
    required this.rules,
  });

  // toJson and fromJson might be needed if TrustAccounts themselves are stored and fetched from Firebase.
  // For now, they will be primarily used by the TrustPaymentEngine, potentially from hardcoded mock data.
}

class TrustStakeholder {
  final String userId; // Links to a User ID in the system
  final String role; // e.g., "Lender", "Equity", "Investor", "Agent", "Contractor"
  final double ownershipPercent; // Used for some types of distributions
  final String paymentMethodId; // Placeholder for future payment integration

  TrustStakeholder({
    required this.userId,
    required this.role,
    this.ownershipPercent = 0.0, // Not all stakeholders have ownership %
    required this.paymentMethodId,
  });
}

class CashFlowRule {
  final String trigger; // e.g., "RentReceived", "SaleProceeds", "InsurancePayout"
  final List<CashDistribution> distributions;
  final String? description; // Optional description of the rule

  CashFlowRule({
    required this.trigger,
    required this.distributions,
    this.description,
  });
}

class CashDistribution {
  final String stakeholderRole; // Identifies which role gets this distribution (e.g., "Equity", "Agent")
                               // This could also be a specific stakeholderId if needed, but role is more flexible for templates.
  final double percent; // Percentage of the inflow amount
  // final double? fixedAmount; // Alternative to percent, could be added later
  final String? condition; // Optional: e.g., "AfterLenderPaid", "ProfitShare" - for more complex waterfalls

  CashDistribution({
    required this.stakeholderRole,
    required this.percent,
    this.condition,
  });
}
