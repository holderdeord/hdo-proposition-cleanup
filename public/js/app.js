angular.module('SidebarController', ['ngHttp', 'ngFilter']);
angular.module('ProgressController', ['ngHttp']);

var SELECT_DATE = 'Velg dato';

function SidebarController ($scope, $http, $filter) {
  $scope.votes = [];
  $scope.dates = [];

  $scope.$watch('selectedDate', function() {
    $scope.votes = [];

    if ($scope.selectedDate) {
      var dateString = $filter('date')(Date.parse($scope.selectedDate), 'yyMMdd');
      $scope.links = [
        {href: 'http://stortinget.no/no/Saker-og-publikasjoner/Publikasjoner/Referater/Stortinget/2010-2011/' + dateString, title: 'Referat'}
      ]
      $scope.fetchVoteList($scope.selectedDate);
    }
  });

  $scope.fetchDates = function() {
    $http({method: 'GET', url: '/dates'}).
      success(function(data, status, headers, config) {
        $scope.dates = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchVoteList = function(date) {
    $http({method: 'GET', url: '/votelist/' + date}).
      success(function(data, status, headers, config) {
        $scope.voteList = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchVotes = function(timestamp) {
    $http({method: 'GET', url: '/votes/' + timestamp}).
      success(function(data, status, headers, config) {
        $scope.votes = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.saveVotes = function() {
    $http({method: 'POST', url: '/votes/', data: $scope.votes}).
      success(function(data, status, headers, config) {
        $scope.votes = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.textFor = function(bool) {
    return {true: 'Ja', false: 'Nei'}[bool];
  };

  $scope.parseDate = function(str) {
    return new Date(str);
  };

  $scope.activeVote = null;

  $scope.openVote = function(vote) {
    $scope.activeVote = vote;
    $scope.votes = [];
    $scope.fetchVotes(vote.time);
  }

  $scope.fetchDates();
};

function PropositionController ($scope) {
  $scope.approve = function() {
    $scope.prop.metadata = $scope.prop.metadata || {};
    $scope.prop.metadata.status = 'approved';

    $scope.saveVotes();
  };

  $scope.reject = function() {
    $scope.prop.metadata = $scope.prop.metadata || {};
    $scope.prop.metadata.reason = window.prompt('Hva er galt?')
    $scope.prop.metadata.status = 'rejected';

    $scope.saveVotes();
  };

  $scope.clear = function() {
    $scope.prop.metadata = {};

    $scope.saveVotes();
  };

  $scope.statusText = function(status) {
    return {
      'approved': 'Godkjent',
      'rejected': 'Avvist'
    }[status]
  };
}

function ProgressController ($scope, $http) {
  this.scope = $scope;
  this.http  = $http;

  $scope.percentage = function(a, b) {
    return a * 100 / b;
  };

  this.update();

  var controller = this;
  setInterval(function() {
    $scope.$apply(controller.update.bind(controller));
  }, 5000)
}

ProgressController.prototype.update = function() {
  var scope = this.scope;

  this.http({method: 'GET', url: '/stats'}).
    success(function(data, status, headers, config) {
      scope.stats = data;
    }).
    error(function(data, status, headers, config) {
      console && console.log("could not update stats");
  });
};