import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../controllers/wallet_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final walletController = Provider.of<WalletController>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.shade700,
                      Colors.orange.shade600,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.wallet,
                              color: Colors.white.withOpacity(0.9),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My Wallet',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Balance Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${walletController.points}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Points',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.info),
                onPressed: () {
                  _showPointsInfoDialog(context);
                },
              ),
            ],
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          icon: LucideIcons.trendingUp,
                          label: 'Earned',
                          value: '+320',
                          color: Colors.green,
                          subtitle: 'This month',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          icon: LucideIcons.trendingDown,
                          label: 'Spent',
                          value: '-180',
                          color: Colors.red,
                          subtitle: 'This month',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          icon: LucideIcons.award,
                          label: 'Rank',
                          value: 'Gold',
                          color: Colors.amber,
                          subtitle: '850+ points',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStatCard(
                          icon: LucideIcons.zap,
                          label: 'Streak',
                          value: '15 days',
                          color: Colors.orange,
                          subtitle: 'Keep going!',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                indicatorColor: cs.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Rewards'),
                  Tab(text: 'Redeem'),
                  Tab(text: 'Withdraw'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionsTab(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),
                const _RewardsTab(),
                const _RedeemTab(),
                const _WithdrawTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showEarnPointsSheet(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: Text(
          'Earn Points',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber.shade700,
      ),
    );
  }

  void _showPointsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.info, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Text(
              'About Points',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earn points by:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _InfoItem('Daily login: +10 points'),
            _InfoItem('Scanning plants: +20 points'),
            _InfoItem('Adding to garden: +15 points'),
            _InfoItem('Completing tasks: +50 points'),
            const SizedBox(height: 16),
            Text(
              'Spend points on:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _InfoItem('Premium diagnoses'),
            _InfoItem('Expert consultations'),
            _InfoItem('Exclusive content'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showEarnPointsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ways to Earn Points',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _EarnPointsCard(
                  icon: LucideIcons.calendar,
                  title: 'Daily Login',
                  points: '+10',
                  description: 'Login every day to earn points',
                  progress: 0.7,
                ),
                _EarnPointsCard(
                  icon: LucideIcons.scanLine,
                  title: 'Scan Plants',
                  points: '+20',
                  description: 'Scan and identify plants',
                  progress: 0.4,
                ),
                _EarnPointsCard(
                  icon: LucideIcons.leaf,
                  title: 'Add to Garden',
                  points: '+15',
                  description: 'Add plants to your garden',
                  progress: 0.6,
                ),
                _EarnPointsCard(
                  icon: LucideIcons.checkCircle,
                  title: 'Complete Tasks',
                  points: '+50',
                  description: 'Finish daily and weekly tasks',
                  progress: 0.2,
                ),
                _EarnPointsCard(
                  icon: LucideIcons.share2,
                  title: 'Refer Friends',
                  points: '+100',
                  description: 'Invite friends to join SeedScan',
                  progress: 0.0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Quick Stat Card Widget
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Transactions Tab
class _TransactionsTab extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _TransactionsTab({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final walletController = Provider.of<WalletController>(context);
    final transactions = walletController.transactions;
    final filteredTransactions = selectedFilter == 'All'
        ? transactions
        : transactions
            .where((t) => selectedFilter == 'Earned'
                ? t.type == TransactionType.earn
                : t.type == TransactionType.spend)
            .toList();

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: selectedFilter == 'All',
                onTap: () => onFilterChanged('All'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Earned',
                isSelected: selectedFilter == 'Earned',
                onTap: () => onFilterChanged('Earned'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Spent',
                isSelected: selectedFilter == 'Spent',
                onTap: () => onFilterChanged('Spent'),
              ),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.fileX,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return _TransactionCard(transaction: transaction);
                  },
                ),
        ),
      ],
    );
  }
}

// Transaction Card
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEarned = transaction.type == TransactionType.earn;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEarned
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEarned ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            color: isEarned ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(transaction.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isEarned ? '+' : '-'}${transaction.amount}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isEarned ? Colors.green : Colors.red,
              ),
            ),
            Text(
              'points',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Rewards Tab
class _RewardsTab extends StatelessWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Available Rewards',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _RewardCard(
          icon: LucideIcons.trophy,
          title: 'Bronze Tier',
          description: 'Unlock basic features',
          points: 0,
          isUnlocked: true,
          color: Colors.brown,
        ),
        _RewardCard(
          icon: LucideIcons.award,
          title: 'Silver Tier',
          description: 'Unlock premium features',
          points: 500,
          isUnlocked: true,
          color: Colors.grey,
        ),
        _RewardCard(
          icon: LucideIcons.crown,
          title: 'Gold Tier',
          description: 'Unlock all features',
          points: 1000,
          isUnlocked: true,
          color: Colors.amber,
        ),
        _RewardCard(
          icon: LucideIcons.gem,
          title: 'Platinum Tier',
          description: 'Exclusive member benefits',
          points: 2000,
          isUnlocked: false,
          color: Colors.cyan,
        ),
      ],
    );
  }
}

// Reward Card
class _RewardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int points;
  final bool isUnlocked;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
    required this.isUnlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked ? color.withOpacity(0.2) : cs.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isUnlocked ? color : cs.onSurfaceVariant,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.checkCircle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnlocked ? 'Unlocked' : '$points points required',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? Colors.green : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Redeem Tab
class _RedeemTab extends StatelessWidget {
  const _RedeemTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Redeem Points',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _RedeemCard(
          icon: LucideIcons.microscope,
          title: 'Premium Diagnosis',
          description: 'AI-powered disease detection',
          points: 30,
          color: Colors.blue,
        ),
        _RedeemCard(
          icon: LucideIcons.userCircle,
          title: 'Expert Consultation',
          description: '30-minute expert session',
          points: 100,
          color: Colors.purple,
        ),
        _RedeemCard(
          icon: LucideIcons.bookOpen,
          title: 'Care Guide',
          description: 'Detailed plant care instructions',
          points: 50,
          color: Colors.green,
        ),
        _RedeemCard(
          icon: LucideIcons.gift,
          title: 'Premium Membership',
          description: '1 month of premium features',
          points: 500,
          color: Colors.orange,
        ),
        _RedeemCard(
          icon: LucideIcons.shoppingBag,
          title: 'Plant Voucher',
          description: '\$20 off at partner nurseries',
          points: 300,
          color: Colors.pink,
        ),
      ],
    );
  }
}

// Redeem Card
class _RedeemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int points;
  final Color color;

  const _RedeemCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showRedeemDialog(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$points pts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    color: cs.onSurface.withOpacity(0.3),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context) {
    final walletController =
        Provider.of<WalletController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$points points',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Balance:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${walletController.points} points',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (walletController.points >= points) {
                final success = await walletController.spendPoints(
                    points, 'Redeemed $title');
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully redeemed $title! 🎉',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Insufficient points. You need ${points - walletController.points} more points.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: walletController.points >= points
                  ? Colors.amber.shade700
                  : Colors.grey,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

// Withdraw Tab
class _WithdrawTab extends StatelessWidget {
  const _WithdrawTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.cyan.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw your points',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Convert points to cash in your mobile wallet',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Select Payment Method',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),

        // JazzCash
        _WithdrawMethodCard(
          logo:
              'https://seeklogo.com/images/J/jazzcash-logo-7ADCB01017-seeklogo.com.png',
          name: 'JazzCash',
          description: 'Instant withdrawal to your JazzCash account',
          minPoints: 500,
          conversionRate: '1 point = PKR 1',
          processingTime: 'Instant',
          backgroundColor: Colors.red.shade50,
          accentColor: Colors.red.shade700,
        ),

        // EasyPaisa
        _WithdrawMethodCard(
          logo:
              'https://seeklogo.com/images/E/easypaisa-logo-248661A05E-seeklogo.com.png',
          name: 'EasyPaisa',
          description: 'Instant withdrawal to your Easypaisa account',
          minPoints: 500,
          conversionRate: '1 point = PKR 1',
          processingTime: 'Instant',
          backgroundColor: Colors.green.shade50,
          accentColor: Colors.green.shade700,
        ),

        const SizedBox(height: 24),

        // Withdrawal Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    color: Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Withdrawal Information',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WithdrawInfoItem('Minimum withdrawal: 500 points (PKR 500)'),
              _WithdrawInfoItem('Maximum withdrawal: 10,000 points/day'),
              _WithdrawInfoItem('Processing fee: Free for first withdrawal'),
              _WithdrawInfoItem('Subsequent withdrawals: 2% fee'),
              _WithdrawInfoItem('Processing time: Instant to 5 minutes'),
            ],
          ),
        ),
      ],
    );
  }
}

// Withdraw Method Card
class _WithdrawMethodCard extends StatelessWidget {
  final String logo;
  final String name;
  final String description;
  final int minPoints;
  final String conversionRate;
  final String processingTime;
  final Color backgroundColor;
  final Color accentColor;

  const _WithdrawMethodCard({
    required this.logo,
    required this.name,
    required this.description,
    required this.minPoints,
    required this.conversionRate,
    required this.processingTime,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showWithdrawDialog(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.5),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.network(
                      logo,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          LucideIcons.wallet,
                          size: 40,
                          color: accentColor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: accentColor.withOpacity(0.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _WithdrawDetailItem(
                      icon: LucideIcons.coins,
                      label: 'Min. Amount',
                      value: '$minPoints pts',
                      color: accentColor,
                    ),
                  ),
                  Expanded(
                    child: _WithdrawDetailItem(
                      icon: LucideIcons.arrowLeftRight,
                      label: 'Rate',
                      value: conversionRate,
                      color: accentColor,
                    ),
                  ),
                  Expanded(
                    child: _WithdrawDetailItem(
                      icon: LucideIcons.clock,
                      label: 'Time',
                      value: processingTime,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.wallet,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Withdraw to $name',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Number Field
              Text(
                '$name Account Number',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '03XX-XXXXXXX',
                  prefixIcon: Icon(LucideIcons.phone, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              Text(
                'Withdrawal Amount (Points)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min. $minPoints points',
                  prefixIcon: Icon(LucideIcons.coins, color: accentColor),
                  suffixText: 'pts',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Conversion Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Conversion Rate:',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversionRate,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Processing Fee:',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Free (First)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Processing Time:',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          processingTime,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Current Balance
              Consumer<WalletController>(
                builder: (context, walletController, _) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Available Balance:',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${walletController.points} pts',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final walletController =
                  Provider.of<WalletController>(context, listen: false);

              if (accountController.text.isEmpty ||
                  amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill all fields',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount < minPoints) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Minimum withdrawal is $minPoints points',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Check if user has sufficient balance
              if (walletController.points < amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Insufficient balance. You need ${amount - walletController.points} more points.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Deduct points from wallet
              walletController.spendPoints(
                amount,
                'Withdrawn to $name (${accountController.text})',
              );

              Navigator.pop(context);

              // Show success dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(LucideIcons.checkCircle,
                          color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Success!',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your withdrawal request has been processed successfully!',
                        style: GoogleFonts.poppins(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PKR $amount',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'will be transferred to',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            Text(
                              accountController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

// Withdraw Detail Item
class _WithdrawDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WithdrawDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Withdraw Info Item
class _WithdrawInfoItem extends StatelessWidget {
  final String text;

  const _WithdrawInfoItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              LucideIcons.checkCircle2,
              size: 14,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;

  const _InfoItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnPointsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String points;
  final String description;
  final double progress;

  const _EarnPointsCard({
    required this.icon,
    required this.title,
    required this.points,
    required this.description,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          points,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: cs.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.shade700,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
