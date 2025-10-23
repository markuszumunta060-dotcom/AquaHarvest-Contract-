# 💧 AquaHarvest - Smart Water Management System

## Overview 🌊

**AquaHarvest** is a comprehensive blockchain-based water management platform that revolutionizes community water harvesting, distribution, and conservation. Built on the Stacks blockchain using Clarity smart contracts, it enables transparent water resource management, community participation, and sustainable water access for everyone.

## Features ✨

### 🏠️ **Community Management**
- **Member Registration**: Secure community member profiles with role-based access
- **Contribution Tracking**: Merit-based point system rewarding community participation
- **Water Allocation**: Fair distribution system with personalized water allowances
- **Location Tracking**: Geographic mapping of community members and resources

### 🏗️ **Well Installation & Management**
- **Well Registration**: Complete well installation with capacity and location tracking
- **Ownership Management**: Clear ownership rights and responsibilities
- **Operational Status**: Real-time monitoring of well operational status
- **Installation Funding**: Transparent cost tracking and community investment

### 🌧️ **Rainwater Harvesting**
- **Harvest Tracking**: Monitor rainfall collection with efficiency metrics
- **Capacity Management**: Automatic overflow protection and level monitoring
- **Cycle Recording**: Historical data of harvesting cycles and performance
- **Efficiency Optimization**: Performance analytics for harvest improvement

### 🚰 **Water Distribution System**
- **Smart Distribution**: Automated water allocation based on member status
- **Emergency Mode**: Free water distribution during crisis situations
- **Cost Calculation**: Transparent pricing for non-emergency distributions
- **Distribution History**: Complete audit trail of all water transactions

### 🔬 **Water Quality Management**
- **Quality Testing**: Comprehensive water quality assessment (pH, bacteria, chemicals)
- **Potability Scoring**: Automated water safety certification system
- **Test History**: Historical quality data for trend analysis
- **Certified Testing**: Community member certification for quality control

### 🔧 **Maintenance System**
- **Scheduled Maintenance**: Proactive well maintenance scheduling
- **Cost Management**: Transparent maintenance cost tracking and payment
- **Maintenance History**: Complete maintenance records for each well
- **Completion Rewards**: Incentive system for maintenance completion

### 🤝 **Community Contributions**
- **Contribution Types**: Multiple ways to contribute (funding, labor, materials)
- **Reward System**: Points-based incentives for community participation
- **Water Allocation Boost**: Increased water access through contributions
- **Contribution History**: Transparent record of all community contributions

## Smart Contract Functions 🔧

### Public Functions

#### Community Management
```clarity
(register-member (name (string-ascii 50)) (location (string-ascii 100)) (role (string-ascii 30)))
```
Register as a community member with role and location.

```clarity
(contribute-to-community (contribution-type (string-ascii 30)) (amount uint) (description (string-ascii 150)))
```
Make financial or resource contributions to the community.

#### Well Management
```clarity
(install-well (name (string-ascii 100)) (location (string-ascii 150)) (capacity-liters uint) (installation-cost uint))
```
Install a new water well with specified capacity and location.

```clarity
(harvest-rainwater (well-id uint) (rainfall-mm uint) (harvest-efficiency uint))
```
Record rainwater harvesting with efficiency tracking.

#### Water Distribution
```clarity
(distribute-water (well-id uint) (recipient principal) (amount-liters uint) (distribution-type (string-ascii 30)))
```
Distribute water to community members with cost calculation.

#### Quality & Maintenance
```clarity
(test-water-quality (well-id uint) (ph-level uint) (bacteria-count uint) (chemical-contamination uint))
```
Test and record water quality metrics.

```clarity
(schedule-maintenance (well-id uint) (maintenance-type (string-ascii 50)) (description (string-ascii 200)) (cost uint))
(complete-maintenance (maintenance-id uint))
```
Schedule and complete well maintenance activities.

#### Administrative
```clarity
(toggle-emergency-mode)
(deactivate-well (well-id uint))
(update-water-allocation (member principal) (new-allocation uint))
```
Admin functions for emergency response and system management.

### Read-Only Functions

```clarity
(get-member (member principal))
(get-well (well-id uint))
(get-distribution (distribution-id uint))
(get-maintenance-record (maintenance-id uint))
(get-harvesting-cycle (well-id uint) (cycle uint))
(get-water-quality-test (well-id uint) (test-date uint))
(get-community-contribution (member principal) (contribution-type (string-ascii 30)))
(get-system-stats)
(calculate-well-efficiency (well-id uint))
```

## Usage Examples 📋

### Register as Community Member
```bash
clarinet console
::set_tx_sender ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
(contract-call? .aquaharvest register-member "Maria Santos" "Block 5, House 23" "Well Manager")
```

### Install New Water Well
```bash
(contract-call? .aquaharvest install-well 
  "Community Well Alpha" 
  "Central Plaza, GPS: -1.2921, 36.8219" 
  u50000 
  u100000)
```

### Harvest Rainwater
```bash
(contract-call? .aquaharvest harvest-rainwater u1 u250 u85)
```

### Distribute Water
```bash
(contract-call? .aquaharvest distribute-water 
  u1 
  'ST2JHG361ZXG51QTQTQPJQZ2...
  u500 
  "Household Daily")
```

### Test Water Quality
```bash
(contract-call? .aquaharvest test-water-quality u1 u72 u3 u1)
```

### Make Community Contribution
```bash
(contract-call? .aquaharvest contribute-to-community 
  "Infrastructure" 
  u25000 
  "Solar pump installation funding")
```

## Development Setup 🛠️

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/docs/build/cli) for blockchain interaction

### Installation
```bash
git clone [repository-url]
cd AquaHarvest-Contract-
clarinet check
```

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet integrate
clarinet deploy --testnet
```

## Water Quality Scoring 💯

The system uses a comprehensive water quality scoring algorithm:

- **pH Level**: Optimal range 6.5-8.5 (scored 0-100)
- **Bacteria Count**: <10 CFU/mL for safe water (scored inversely)  
- **Chemical Contamination**: <5 ppm for potable water (scored inversely)
- **Potability Score**: Combined score determining water safety certification

Water scoring >75 points receives automatic safety certification.

## Economic Model 💰

### Cost Structure
- **Normal Distribution**: 10 STX per liter (customizable)
- **Emergency Distribution**: Free during emergency mode
- **Installation Costs**: Member-determined well installation fees
- **Maintenance Costs**: Transparent maintenance pricing

### Reward System
- **Well Installation**: +50 contribution points
- **Quality Testing**: +25 contribution points  
- **Maintenance Completion**: +30 contribution points
- **Community Contributions**: +1 point per 100 STX contributed

### Water Allocation
- **Base Allocation**: 1,000 liters per registered member
- **Contribution Bonus**: +1 liter per 50 STX contributed
- **Emergency Override**: Unlimited during emergency mode

## Security Features 🔒

- **Role-Based Access**: Multi-level permission system
- **Owner Verification**: Well owners control their resources
- **Community Verification**: Member-only participation
- **Emergency Controls**: Admin override for crisis situations
- **Input Validation**: Comprehensive parameter checking
- **Overflow Protection**: Automatic capacity management

## System Analytics 📊

Track comprehensive metrics:
- **Total Wells**: Active water harvesting installations
- **Water Harvested**: Total rainwater collected (liters)
- **Water Distributed**: Community water consumption tracking
- **Well Efficiency**: Utilization and quality performance metrics
- **Maintenance Schedule**: Proactive system health monitoring
- **Community Health**: Member participation and contribution analytics

## Emergency Response 🚨

- **Emergency Mode**: Admin-controlled free water distribution
- **Crisis Override**: Bypass normal allocation limits
- **Priority Distribution**: Critical needs during disasters
- **Community Mobilization**: Rapid response coordination

## Future Enhancements 🔮

- **IoT Integration**: Automated well level and quality sensors
- **Weather API**: Real-time rainfall prediction and optimization
- **Mobile App**: Community access via smartphones  
- **Satellite Monitoring**: Remote well performance tracking
- **AI Optimization**: Machine learning for harvest prediction
- **Cross-Community Trading**: Inter-community water exchanges

## Environmental Impact 🌱

- **Water Conservation**: Efficient rainwater harvesting reduces waste
- **Community Resilience**: Local water security independence
- **Sustainable Access**: Long-term water availability planning
- **Quality Assurance**: Safe water for community health
- **Resource Optimization**: Data-driven water management

## Contributing 🤝

Join the AquaHarvest community! Whether you're a water engineer, blockchain developer, community organizer, or simply passionate about water access - your contributions help bring clean water to communities worldwide.

## License 📄

Open source under MIT License - because clean water access should be universal.

---

**🌊 Join AquaHarvest and help build a water-secure future for all communities! 💙**

