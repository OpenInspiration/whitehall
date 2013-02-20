Feature: Administering worldwide organisation
  As a citizen interested in UK gov activity around the world, I want there to be profiles of the world organisation (eg embassies, DFID offices, UKTI branches) in each worldwide location, so I can see which organisation are active in each location and read more about them.

  Acceptance criteria:

  * Each world organisation has:
    * a unique name e.g. "British Embassy in Madrid" and a URL "/world/offices/british-embassy-in-madrid" which is generated from the name
    * a text short summary and markdown long description.
    * multiple social media links (like orgs)
    * multiple sets of office information (like orgs)
    * a logo formatted name (always using the standard HMG crest for now)
  * Each world organisation can be associated with 1+ world locations, and shows on the world locations page to which they are associated (see mock up on the [ticket](https://www.pivotaltracker.com/story/show/41026113))
  * Each can have corporate information pages (like orgs)

  Background:
    Given I am a GDS editor

  Scenario: Creating worldwide organisation
    Given the organisation "Department of Beards" exists
    When I create a worldwide organisation "Department of Beards in France" sponsored by the "Department of Beards" with a summary, description and services
    Then I should see the worldwide organisation information on the public website
    And the "Department of Beards in France" logo should show correctly with the HMG crest
    And I should see that it is part of the "Department of Beards"
    When I update the worldwide organisation to set the name to "Department of Beards and Moustaches in France"
    Then I should see the updated worldwide organisation information on the public website
    When I delete the worldwide organisation
    Then the worldwide organisation should not be visible from the public website

  Scenario: Managing social media links
    Given a worldwide organisation "Department of Beards in France"
    Given a social media service "Twooter"
    When I add a "Twooter" social media link "http://twooter.com/beards-in-france"
    Then the social link should be shown on the public website

  Scenario: Managing office information
    Given a worldwide organisation "Department of Beards in France"
    When I add an "Hair division" office with address and phone number
    Then the "Hair division" details should be shown on the public website

  Scenario: Creating a worldwide organisation in a particular world location
    Given that the world location "France" exists
    When I create a new worldwide organisation "Department of Beards in France" in "France"
    Then I should see the worldwide organisation "Department of Beards in France" on the "France" world location page

  Scenario: Choosing the main office for a worldwide organisation with multiple offices
    Given a worldwide organisation "Department of Beards in France" with offices "Head office" and "Branch office"
    When I choose "Branch office" to be the main office
    Then the "Branch office" should be shown as the main office on the public website
    When I choose "Head office" to be the main office
    Then the "Head office" should be shown as the main office on the public website

  Scenario: Creating a worldwide organisation in particular world location with a sponsor
    Given the organisation "Department of Beards" exists
    Given that the world location "France" exists
    When I create a new worldwide organisation "Department of Beards in France" in  "France" sponsored by the "Department of Beards"
    Then I should see the worldwide organisation "Department of Beards in France" on the "France" world location page
    And I should see that it is part of the "Department of Beards"

  Scenario: Adding office hours to a worldwide organisation
  Scenario: Adding corporate information pages to worldwide organisations

  Scenario: Adding a new translation
    Given a worldwide organisation "Department of Beards in France" exists for the country "France" with translations into "fr"
    When I add a new translation to the worldwide organisation "Department of Beards in France" with:
      | locale      | Français                                          |
      | name        | Département des barbes en France                  |
      | summary     | Nous nous occupons de la pilosité faciale du pays |
      | description | Barbes, moustaches, même rouflaquettes            |
      | services    | Montante, pommades, humide rase                   |
    Then when viewing the worldwide organisation "Department of Beards in France" with the locale "fr" I should see:
      | name        | Département des barbes en France                  |
      | summary     | Nous nous occupons de la pilosité faciale du pays |
      | description | Barbes, moustaches, même rouflaquettes            |
      | services    | Montante, pommades, humide rase                   |

  Scenario: Editing an existing translation
    Given a worldwide organisation "Department of Beards in France" exists with a translation for the locale "Français"
    When I edit the "Français" translation for the worldwide organisation "Department of Beards in France" setting:
      | name        | Le super département des barbes en France         |
      | summary     | Nous nous occupons de la pilosité faciale du pays |
      | description | Barbes, moustaches, même rouflaquettes            |
      | services    | Montante, pommades, humide rase                   |
    Then when viewing the worldwide organisation "Department of Beards in France" with the locale "fr" I should see:
      | name        | Le super département des barbes en France         |
      | summary     | Nous nous occupons de la pilosité faciale du pays |
      | description | Barbes, moustaches, même rouflaquettes            |
      | services    | Montante, pommades, humide rase                   |
