angular.module('SidebarController', ['ngHttp', 'ngFilter']);
angular.module('ProgressController', ['ngHttp']);

function SidebarController ($scope, $http, $filter) {
  var issueCache, spinner;

  issueCache = {};
  spinner    = document.getElementById('spinner');

  $scope.votes = [];
  $scope.dates = [];

  $scope.$watch('selectedDate', function() {
    $scope.votes = [];

    if ($scope.selectedDate) {
      var dateString = $filter('date')($scope.parseDate($scope.selectedDate), 'yyMMdd');
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
    $scope.voteList = [];

    var str = $filter('date')($scope.parseDate(date), 'yyyy-MM-dd H:mm:ss');
    $http({method: 'GET', url: '/votelist/' + str}).
      success(function(data, status, headers, config) {
        $scope.voteList = data;
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchVotes = function(timestamp) {
    var str = $filter('date')($scope.parseDate(timestamp), 'yyyy-MM-dd H:mm:ss');

    spinner.style.display = 'block';

    $http({method: 'GET', url: '/votes/' + str}).
      success(function(votes, status, headers, config) {
        $scope.votes = votes;
        spinner.style.display = 'none';
        _.each(votes, function(vote) {
          $scope.fetchIssuesFor(vote);
        });
      }).
      error(function(data, status, headers, config) {
        alert('' + status + data);
      });
  };

  $scope.fetchIssuesFor = function(vote) {
    function addIssue(issue) {
      vote.issues = vote.issues || [];
      vote.issues.push(issue);
      vote.issues = _.sortBy(vote.issues, 'description');
    }

    _.each(vote.externalIssueId.split(','), function(id) {
     if (issueCache[id]) {
         addIssue(issueCache[id])
         return;
     }

     $http({method: 'GET', url: 'http://next.holderdeord.no/parliament-issues/' + id + '.json'}).
       success(function(data, status, headers, config) {
         issueCache[id] = data;
         addIssue(data)
       }).
       error(function(data, status, headers, config) {
         console && console.log(status + ': ' + data);
       });
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


function VoteController ($scope) {
}

